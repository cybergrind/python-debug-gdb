#!/usr/bin/env python3
"""
Demonstrates GIL contention visible in GDB.

1. Starts several worker threads doing pure-Python computation.
2. After workers settle, one thread grabs the GIL via a C extension
   that calls sleep() without Py_BEGIN_ALLOW_THREADS.
3. All workers end up blocked in take_gil() — visible in 'thread apply all bt'.
"""

import os
import sys
import threading
import time

sys.path.insert(0, "/script")
import gilholder


def worker():
    """Busy-loop doing Python work that requires the GIL."""
    while True:
        total = sum(range(10000))
        _ = [i ** 2 for i in range(1000)]


def gil_blocker():
    """Grab the GIL from C and hold it for 60 s."""
    print("gil_blocker: holding GIL for 60 seconds …", flush=True)
    gilholder.hold_gil(60)
    print("gil_blocker: released", flush=True)


if __name__ == "__main__":
    print(f"PID: {os.getpid()}", flush=True)

    for i in range(5):
        t = threading.Thread(target=worker, name=f"worker-{i}", daemon=True)
        t.start()
        print(f"Started {t.name}", flush=True)

    time.sleep(2)

    # Signal readiness BEFORE starting blocker (once the blocker grabs the
    # GIL, the main thread won't be able to do any Python work either).
    with open("/tmp/gil_demo_ready", "w") as f:
        f.write(str(os.getpid()))
    print("ready file written, starting GIL blocker …", flush=True)

    blocker = threading.Thread(target=gil_blocker, name="gil-blocker", daemon=True)
    blocker.start()

    # time.sleep releases the GIL, so the main thread will give it up and
    # then block in take_gil() when it tries to reacquire — just like the
    # workers.
    time.sleep(3600)
