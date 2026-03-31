# python-debug

Docker container for debugging Python processes with GDB, providing mixed C/Python stack traces.

## What's inside

- Python 3.13 with debug-friendly build
- GDB with Python extensions
- [uv](https://github.com/astral-sh/uv) package manager
- FastAPI + Gunicorn sample server
- Scripts to attach to a running process, dump full backtraces (C + Python frames), and detach cleanly

## Quick start

```bash
# Build the image
make image

# Run interactive shell inside the container
make run

# Run end-to-end test (build, start server, dump trace, verify server survives)
make test
```

## Make targets

| Target     | Description                                                        |
|------------|--------------------------------------------------------------------|
| `image`    | Build the Docker image                                             |
| `run`      | Start an interactive shell with `SYS_PTRACE` capability            |
| `test`     | E2E test: start Gunicorn server, dump backtrace, verify it survives |
| `test-gil` | Demonstrate GIL contention debugging                               |
| `test-gc`  | Demonstrate GC freeze debugging                                    |

## Scripts (`script/`)

- **server.py** -- FastAPI app running under Gunicorn (1 worker)
- **dump_trace.sh** -- Attach GDB to a process, dump all threads' C + Python backtraces, then detach
- **dump_gc_trace.sh** -- Same as above but targeting GC activity
- **gil_demo.py** -- Reproduces GIL contention for debugging practice
- **gc_demo.py** -- Reproduces GC pressure for debugging practice
- **gilholder.c** -- C extension that holds the GIL (compiled during image build)

## Requirements

- Docker (with `--cap-add=SYS_PTRACE` support)
- GNU Make
