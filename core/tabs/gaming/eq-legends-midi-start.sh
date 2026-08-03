#!/bin/sh -e

HOOK_DIR=$(dirname -- "$0")
HOOK_DIR=$(cd -- "$HOOK_DIR" && pwd)
DATA_HOME=$(cd -- "$HOOK_DIR/../.." && pwd)
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
SOUNDFONT="$DATA_HOME/sounds/sf2/SC-55 Roland SOUNDCanvas Up.sf2"
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	RUNTIME_DIR="$XDG_RUNTIME_DIR/linutil-eq-midi"
else
	RUNTIME_DIR="${TMPDIR:-/tmp}/linutil-eq-midi-$(id -u)"
fi
STATE_DIR="$STATE_HOME/linutil"
PID_FILE="$RUNTIME_DIR/fluidsynth.pid"
REFCOUNT_FILE="$RUNTIME_DIR/launch-count"
LOCK_FILE="$RUNTIME_DIR/state.lock"
LOG_FILE="$STATE_DIR/eq-legends-midi.log"
MIDI_CLIENT_NAME="EQ-Legends"
MIDI_PORT_NAME="EQ-Legends"

umask 077

fail() {
	printf "%s\n" "eq-legends-midi: $*" >&2
	exit 1
}

process_start_time() {
	process_pid="$1"
	[ -r "/proc/$process_pid/stat" ] || return 1
	process_stat=$(sed -n '1p' "/proc/$process_pid/stat") || return 1
	process_stat=${process_stat##*) }
	# The remaining proc fields are whitespace-delimited numeric values.
	# shellcheck disable=SC2086
	set -- $process_stat
	[ "$#" -ge 20 ] || return 1
	shift 19
	case "$1" in
	'' | *[!0-9]*) return 1 ;;
	esac
	printf "%s\n" "$1"
}

process_matches_start_time() {
	process_pid="$1"
	expected_start_time="$2"
	current_start_time=$(process_start_time "$process_pid") || return 1
	[ "$current_start_time" = "$expected_start_time" ]
}

owned_process_is_running() {
	process_pid="$1"
	expected_start_time="$2"
	process_matches_start_time "$process_pid" "$expected_start_time" || return 1
	process_name=$(ps -p "$process_pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)
	[ "$process_name" = "fluidsynth" ]
}

ensure_runtime_dir() {
	if mkdir -m 0700 "$RUNTIME_DIR" 2>/dev/null; then
		return 0
	fi

	[ -d "$RUNTIME_DIR" ] && [ ! -L "$RUNTIME_DIR" ] || fail "runtime path is unsafe: $RUNTIME_DIR"
	runtime_owner=$(stat -c '%u' -- "$RUNTIME_DIR" 2>/dev/null) || fail "unable to inspect runtime path: $RUNTIME_DIR"
	[ "$runtime_owner" = "$(id -u)" ] || fail "runtime path is not owned by the current user: $RUNTIME_DIR"
	chmod 0700 "$RUNTIME_DIR"
}

acquire_lock() {
	[ ! -L "$LOCK_FILE" ] || fail "runtime lock path is unsafe: $LOCK_FILE"
	[ ! -e "$LOCK_FILE" ] || [ -f "$LOCK_FILE" ] || fail "runtime lock path is not a file: $LOCK_FILE"
	exec 9>>"$LOCK_FILE"
	chmod 0600 "$LOCK_FILE"
	flock -w 15 9 || fail "timed out waiting for the FluidSynth lifecycle lock"
}

read_launch_count() {
	LAUNCH_COUNT=0
	[ -f "$REFCOUNT_FILE" ] || return 0
	LAUNCH_COUNT=$(sed -n '1p' "$REFCOUNT_FILE")
	case "$LAUNCH_COUNT" in
	'' | *[!0-9]*) fail "invalid launch count in $REFCOUNT_FILE" ;;
	esac
	[ "$LAUNCH_COUNT" -gt 0 ] || fail "invalid launch count in $REFCOUNT_FILE"
}

write_launch_count() {
	printf "%s\n" "$1" >"$REFCOUNT_FILE"
}

command -v fluidsynth >/dev/null 2>&1 || fail "fluidsynth is not installed"
command -v aconnect >/dev/null 2>&1 || fail "aconnect is not installed"
command -v flock >/dev/null 2>&1 || fail "flock is not installed"
command -v nohup >/dev/null 2>&1 || fail "nohup is not installed"
command -v ps >/dev/null 2>&1 || fail "ps is not installed"
command -v stat >/dev/null 2>&1 || fail "stat is not installed"
[ -f "$SOUNDFONT" ] || fail "SoundFont not found: $SOUNDFONT"

ensure_runtime_dir
mkdir -p "$STATE_DIR"
acquire_lock

owned_pid=""
owned_start_time=""
if [ -f "$PID_FILE" ]; then
	owned_pid=$(sed -n '1p' "$PID_FILE")
	owned_start_time=$(sed -n '2p' "$PID_FILE")
	case "$owned_pid:$owned_start_time" in
	*[!0-9:]* | :* | *:)
		rm -f "$PID_FILE"
		owned_pid=""
		owned_start_time=""
		;;
	*)
		if ! owned_process_is_running "$owned_pid" "$owned_start_time"; then
			rm -f "$PID_FILE"
			owned_pid=""
			owned_start_time=""
		fi
		;;
	esac
fi

if aconnect -l 2>/dev/null | grep -q "client [0-9][0-9]*: '$MIDI_CLIENT_NAME'"; then
	[ -n "$owned_pid" ] || fail "an unmanaged $MIDI_CLIENT_NAME MIDI client is already running"
	read_launch_count
	if [ "$LAUNCH_COUNT" -eq 0 ]; then
		LAUNCH_COUNT=1
	fi
	write_launch_count $((LAUNCH_COUNT + 1))
	exit 0
fi

if [ -n "$owned_pid" ]; then
	printf "%s\n" "eq-legends-midi: reclaiming an owned FluidSynth process without a MIDI port; see $LOG_FILE" >&2
	kill "$owned_pid" 2>/dev/null || true
	stop_attempt=0
	while owned_process_is_running "$owned_pid" "$owned_start_time" && [ "$stop_attempt" -lt 5 ]; do
		stop_attempt=$((stop_attempt + 1))
		sleep 1
	done
	if owned_process_is_running "$owned_pid" "$owned_start_time"; then
		kill -KILL "$owned_pid" 2>/dev/null || true
	fi
	rm -f "$PID_FILE" "$REFCOUNT_FILE"
	fail "an owned FluidSynth process is running without a MIDI port; see $LOG_FILE"
fi
rm -f "$REFCOUNT_FILE"

audio_drivers=$(fluidsynth -a help 2>&1 || true)
midi_drivers=$(fluidsynth -m help 2>&1 || true)
printf "%s\n" "$midi_drivers" | grep -q "alsa_seq" || fail "FluidSynth lacks the required ALSA sequencer MIDI driver"

audio_driver=""
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && printf "%s\n" "$audio_drivers" | grep -q "pipewire"; then
	audio_driver="pipewire"
elif {
	[ -n "${PULSE_SERVER:-}" ] || { [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -S "$XDG_RUNTIME_DIR/pulse/native" ]; }
} && printf "%s\n" "$audio_drivers" | grep -q "pulseaudio"; then
	audio_driver="pulseaudio"
elif printf "%s\n" "$audio_drivers" | grep -q "alsa"; then
	audio_driver="alsa"
fi

[ -n "$audio_driver" ] || fail "no supported PipeWire, PulseAudio, or ALSA audio driver is available"

nohup fluidsynth -i -a "$audio_driver" -m alsa_seq \
	-o "midi.alsa_seq.id=$MIDI_CLIENT_NAME" \
	-o "midi.portname=$MIDI_PORT_NAME" \
	"$SOUNDFONT" 9>&- >"$LOG_FILE" 2>&1 &
fluidsynth_pid=$!
fluidsynth_start_time=$(process_start_time "$fluidsynth_pid") || {
	kill "$fluidsynth_pid" 2>/dev/null || true
	wait "$fluidsynth_pid" 2>/dev/null || true
	fail "unable to record the FluidSynth process identity; see $LOG_FILE"
}
printf "%s\n%s\n" "$fluidsynth_pid" "$fluidsynth_start_time" >"$PID_FILE"

attempt=0
while [ "$attempt" -lt 10 ]; do
	if aconnect -l 2>/dev/null | grep -q "client [0-9][0-9]*: '$MIDI_CLIENT_NAME'"; then
		write_launch_count 1
		exit 0
	fi

	if ! owned_process_is_running "$fluidsynth_pid" "$fluidsynth_start_time"; then
		rm -f "$PID_FILE" "$REFCOUNT_FILE"
		tail -n 20 "$LOG_FILE" >&2 || true
		fail "FluidSynth exited before its MIDI port became ready"
	fi

	attempt=$((attempt + 1))
	sleep 1
done

if owned_process_is_running "$fluidsynth_pid" "$fluidsynth_start_time"; then
	kill "$fluidsynth_pid" 2>/dev/null || true
fi
wait "$fluidsynth_pid" 2>/dev/null || true
rm -f "$PID_FILE" "$REFCOUNT_FILE"
fail "FluidSynth started but its MIDI port did not become ready; see $LOG_FILE"
