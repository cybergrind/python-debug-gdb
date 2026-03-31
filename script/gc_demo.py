#!/usr/bin/env python3
"""
Demonstrates a GC-induced freeze visible in GDB.

Worker threads do pure-Python computation. The main thread continuously
creates cyclic garbage whose __del__ calls gilholder.finalizer_signal().

GDB sets a breakpoint on finalizer_signal, so when it fires we are
*inside* the garbage collector's finalization phase.  All other threads
will be blocked on the GIL — the classic "GC freeze".
"""

import gc
import os
import sys
import threading
import time

sys.path.insert(0, "/script")
import gilholder


class CyclicGarbage:
    """Object that forms reference cycles and has a __del__ finalizer."""

    def __init__(self):
        self.ref = None
        self.payload = list(range(100))

    def __del__(self):
        gilholder.finalizer_signal()


def worker():
    """Busy-loop doing Python work — will be blocked on the GIL during GC."""
    while True:
        total = sum(range(10000))
        _ = [i ** 2 for i in range(1000)]


def garbage_factory():
    """Create cyclic garbage in a loop so GC fires repeatedly."""
    while True:
        batch = []
        for _ in range(5000):
            a = CyclicGarbage()
            b = CyclicGarbage()
            a.ref = b
            b.ref = a
            batch.append(a)
        del batch
        gc.collect()
        time.sleep(0.1)


if __name__ == "__main__":
    print(f"PID: {os.getpid()}", flush=True)

    for i in range(4):
        t = threading.Thread(target=worker, name=f"worker-{i}", daemon=True)
        t.start()
        print(f"Started {t.name}", flush=True)

    time.sleep(1)

    # Write ready file BEFORE entering garbage_factory — once GC grabs
    # the GIL in the tight loop the main thread will barely yield.
    with open("/tmp/gc_demo_ready", "w") as f:
        f.write(str(os.getpid()))
    print("Ready — entering garbage factory …", flush=True)

    garbage_factory()
