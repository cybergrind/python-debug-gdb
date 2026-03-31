#!/usr/bin/env bash
set -euo pipefail

# Usage: dump_gc_trace.sh PID
# Attaches GDB, sets a breakpoint on gilholder_finalizer_signal (called
# from __del__ during GC), continues until the breakpoint fires, then
# dumps all thread backtraces.

TARGET_PID="${1:?usage: dump_gc_trace.sh PID}"

echo "=== Attaching to PID=$TARGET_PID, waiting for GC finalizer ==="

gdb -batch -nx \
    -ex "set pagination off" \
    -ex "attach $TARGET_PID" \
    -ex "break gilholder_finalizer_signal" \
    -ex "continue" \
    -ex "echo === Breakpoint hit inside GC finalizer ===\n" \
    -ex "info threads" \
    -ex "thread apply all bt" \
    -ex "thread apply all py-bt" \
    -ex "detach" \
    -ex "quit"

echo "=== Done, process should still be running ==="
