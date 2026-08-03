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
LOG_FILE="$STATE_DIR/eq-legends-midi.log"
MIDI_CLIENT_NAME="EQ-Legends"
MIDI_PORT_NAME="EQ-Legends"

fail() {
	printf "%s\n" "eq-legends-midi: $*" >&2
	exit 1
}

command -v fluidsynth >/dev/null 2>&1 || fail "fluidsynth is not installed"
command -v aconnect >/dev/null 2>&1 || fail "aconnect is not installed"
command -v nohup >/dev/null 2>&1 || fail "nohup is not installed"
[ -f "$SOUNDFONT" ] || fail "SoundFont not found: $SOUNDFONT"

[ ! -L "$RUNTIME_DIR" ] || fail "runtime path must not be a symbolic link: $RUNTIME_DIR"
mkdir -p "$RUNTIME_DIR" "$STATE_DIR"
chmod 0700 "$RUNTIME_DIR"

if aconnect -l 2>/dev/null | grep -q "client [0-9][0-9]*: '$MIDI_CLIENT_NAME'"; then
	exit 0
fi

if [ -f "$PID_FILE" ]; then
	old_pid=$(sed -n '1p' "$PID_FILE")
	case "$old_pid" in
	'' | *[!0-9]*) rm -f "$PID_FILE" ;;
	*)
		if kill -0 "$old_pid" 2>/dev/null; then
			old_command=$(ps -p "$old_pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)
			if [ "$old_command" = "fluidsynth" ]; then
				fail "an owned FluidSynth process is running without a MIDI port; see $LOG_FILE"
			fi
		fi
		rm -f "$PID_FILE"
		;;
	esac
fi

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

nohup fluidsynth -is -a "$audio_driver" -m alsa_seq \
	-o "midi.alsa_seq.id=$MIDI_CLIENT_NAME" \
	-o "midi.portname=$MIDI_PORT_NAME" \
	"$SOUNDFONT" >"$LOG_FILE" 2>&1 &
fluidsynth_pid=$!
printf "%s\n" "$fluidsynth_pid" >"$PID_FILE"

attempt=0
while [ "$attempt" -lt 10 ]; do
	if aconnect -l 2>/dev/null | grep -q "client [0-9][0-9]*: '$MIDI_CLIENT_NAME'"; then
		exit 0
	fi

	if ! kill -0 "$fluidsynth_pid" 2>/dev/null; then
		rm -f "$PID_FILE"
		tail -n 20 "$LOG_FILE" >&2 || true
		fail "FluidSynth exited before its MIDI port became ready"
	fi

	attempt=$((attempt + 1))
	sleep 1
done

kill "$fluidsynth_pid" 2>/dev/null || true
wait "$fluidsynth_pid" 2>/dev/null || true
rm -f "$PID_FILE"
fail "FluidSynth started but its MIDI port did not become ready; see $LOG_FILE"
