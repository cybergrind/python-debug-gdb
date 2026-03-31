#!/usr/bin/env bash
set -euo pipefail

# Usage: dump_trace.sh [PID]
# Without arguments, finds the gunicorn worker automatically.

if [ $# -ge 1 ]; then
    TARGET_PID="$1"
    echo "=== Attaching to PID=$TARGET_PID ==="
else
    MASTER_PID=$(pgrep -f 'gunicorn.*server:app' | head -1)
    if [ -z "$MASTER_PID" ]; then
        echo "ERROR: gunicorn master not found" >&2
        exit 1
    fi
    TARGET_PID=$(pgrep -P "$MASTER_PID" | head -1)
    if [ -z "$TARGET_PID" ]; then
        echo "ERROR: gunicorn worker not found (master=$MASTER_PID)" >&2
        exit 1
    fi
    echo "=== Attaching to gunicorn worker PID=$TARGET_PID (master=$MASTER_PID) ==="
fi

gdb -batch -nx \
    -ex "set pagination off" \
    -ex "attach $TARGET_PID" \
    -ex "info threads" \
    -ex "thread apply all bt" \
    -ex "thread apply all py-bt" \
    -ex "detach" \
    -ex "quit"

echo "=== Done, process should still be running ==="
