#!/bin/sh -e

if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	RUNTIME_DIR="$XDG_RUNTIME_DIR/linutil-eq-midi"
else
	RUNTIME_DIR="${TMPDIR:-/tmp}/linutil-eq-midi-$(id -u)"
fi
PID_FILE="$RUNTIME_DIR/fluidsynth.pid"

[ ! -L "$RUNTIME_DIR" ] || {
	printf "%s\n" "eq-legends-midi: refusing symbolic-link runtime path $RUNTIME_DIR" >&2
	exit 1
}
[ -f "$PID_FILE" ] || exit 0

fluidsynth_pid=$(sed -n '1p' "$PID_FILE")
case "$fluidsynth_pid" in
'' | *[!0-9]*)
	rm -f "$PID_FILE"
	exit 0
	;;
esac

if ! kill -0 "$fluidsynth_pid" 2>/dev/null; then
	rm -f "$PID_FILE"
	exit 0
fi

process_name=$(ps -p "$fluidsynth_pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)
if [ -z "$process_name" ] && ! kill -0 "$fluidsynth_pid" 2>/dev/null; then
	rm -f "$PID_FILE"
	exit 0
fi
if [ "$process_name" != "fluidsynth" ]; then
	printf "%s\n" "eq-legends-midi: refusing to stop unrelated process $fluidsynth_pid" >&2
	rm -f "$PID_FILE"
	exit 1
fi

kill "$fluidsynth_pid"
attempt=0
while kill -0 "$fluidsynth_pid" 2>/dev/null && [ "$attempt" -lt 5 ]; do
	attempt=$((attempt + 1))
	sleep 1
done

if kill -0 "$fluidsynth_pid" 2>/dev/null; then
	kill -KILL "$fluidsynth_pid" 2>/dev/null || true
fi

rm -f "$PID_FILE"
