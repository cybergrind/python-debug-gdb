#!/usr/bin/env bash
set -euo pipefail

# Find gunicorn worker PID (child of the master process)
MASTER_PID=$(pgrep -f 'gunicorn.*server:app' | head -1)
if [ -z "$MASTER_PID" ]; then
    echo "ERROR: gunicorn master not found" >&2
    exit 1
fi

WORKER_PID=$(pgrep -P "$MASTER_PID" | head -1)
if [ -z "$WORKER_PID" ]; then
    echo "ERROR: gunicorn worker not found (master=$MASTER_PID)" >&2
    exit 1
fi

echo "=== Attaching to gunicorn worker PID=$WORKER_PID (master=$MASTER_PID) ==="

gdb -batch -nx \
    -ex "set pagination off" \
    -ex "attach $WORKER_PID" \
    -ex "info threads" \
    -ex "thread apply all bt" \
    -ex "thread apply all py-bt" \
    -ex "detach" \
    -ex "quit"

echo "=== Done, process should still be running ==="
