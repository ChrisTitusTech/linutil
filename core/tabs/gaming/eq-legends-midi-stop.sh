#!/bin/sh -e

if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	RUNTIME_DIR="$XDG_RUNTIME_DIR/linutil-eq-midi"
else
	RUNTIME_DIR="${TMPDIR:-/tmp}/linutil-eq-midi-$(id -u)"
fi
PID_FILE="$RUNTIME_DIR/fluidsynth.pid"
LOCK_FILE="$RUNTIME_DIR/state.lock"
PENDING_DIR="$RUNTIME_DIR/pending"

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

managed_game_count() {
	managed_count=0
	game_pids=$(pgrep -u "$(id -u)" -f '(^|[\\/])([Ll]aunch[Pp]ad|eqgame)[.]exe([[:space:]]|$)' || true)
	# Candidate PIDs are newline-delimited decimal values from pgrep.
	# shellcheck disable=SC2086
	for game_pid in $game_pids; do
		if [ -r "/proc/$game_pid/environ" ] && tr '\000' '\n' <"/proc/$game_pid/environ" | grep -Fqx "WINEPREFIX=$WINEPREFIX"; then
			managed_count=$((managed_count + 1))
		fi
	done
	printf "%s\n" "$managed_count"
}

pending_launch_count() {
	pending_count=0
	for pending_token in "$PENDING_DIR"/launch.*; do
		[ -f "$pending_token" ] || continue
		watcher_pid=$(sed -n '2p' "$pending_token")
		watcher_start_time=$(sed -n '3p' "$pending_token")
		case "$watcher_pid:$watcher_start_time" in
		*[!0-9:]* | :* | *:)
			pending_count=$((pending_count + 1))
			continue
			;;
		esac
		if ! process_matches_start_time "$watcher_pid" "$watcher_start_time"; then
			rm -f "$pending_token"
			continue
		fi
		pending_count=$((pending_count + 1))
	done
	printf "%s\n" "$pending_count"
}

acquire_lock() {
	[ ! -L "$LOCK_FILE" ] || fail "runtime lock path is unsafe: $LOCK_FILE"
	[ ! -e "$LOCK_FILE" ] || [ -f "$LOCK_FILE" ] || fail "runtime lock path is not a file: $LOCK_FILE"
	exec 9>>"$LOCK_FILE"
	chmod 0600 "$LOCK_FILE"
	flock -w 15 9 || fail "timed out waiting for the FluidSynth lifecycle lock"
}

[ -e "$RUNTIME_DIR" ] || exit 0
command -v flock >/dev/null 2>&1 || fail "flock is not installed"
command -v pgrep >/dev/null 2>&1 || fail "pgrep is not installed"
command -v ps >/dev/null 2>&1 || fail "ps is not installed"
command -v stat >/dev/null 2>&1 || fail "stat is not installed"
# Lutris passes the configured Wine environment to both lifecycle hooks.
[ -n "${WINEPREFIX:-}" ] || fail "WINEPREFIX was not provided by Lutris"
[ -d "$RUNTIME_DIR" ] && [ ! -L "$RUNTIME_DIR" ] || fail "runtime path is unsafe: $RUNTIME_DIR"
runtime_owner=$(stat -c '%u' -- "$RUNTIME_DIR" 2>/dev/null) || fail "unable to inspect runtime path: $RUNTIME_DIR"
[ "$runtime_owner" = "$(id -u)" ] || fail "runtime path is not owned by the current user: $RUNTIME_DIR"

acquire_lock
[ -f "$PID_FILE" ] || {
	exit 0
}

fluidsynth_pid=$(sed -n '1p' "$PID_FILE")
fluidsynth_start_time=$(sed -n '2p' "$PID_FILE")
case "$fluidsynth_pid:$fluidsynth_start_time" in
*[!0-9:]* | :* | *:)
	rm -f "$PID_FILE"
	exit 0
	;;
esac

if ! process_matches_start_time "$fluidsynth_pid" "$fluidsynth_start_time"; then
	rm -f "$PID_FILE"
	exit 0
fi

process_name=$(ps -p "$fluidsynth_pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)
if [ "$process_name" != "fluidsynth" ]; then
	printf "%s\n" "eq-legends-midi: refusing to stop unrelated process $fluidsynth_pid" >&2
	rm -f "$PID_FILE"
	exit 1
fi

managed_count=$(managed_game_count)
pending_count=$(pending_launch_count)
if [ "$managed_count" -gt 0 ] || [ "$pending_count" -gt 0 ]; then
	exit 0
fi

if owned_process_is_running "$fluidsynth_pid" "$fluidsynth_start_time"; then
	kill "$fluidsynth_pid" 2>/dev/null || true
fi
attempt=0
while owned_process_is_running "$fluidsynth_pid" "$fluidsynth_start_time" && [ "$attempt" -lt 5 ]; do
	attempt=$((attempt + 1))
	sleep 1
done

if owned_process_is_running "$fluidsynth_pid" "$fluidsynth_start_time"; then
	kill -KILL "$fluidsynth_pid" 2>/dev/null || true
fi

rm -f "$PID_FILE"
