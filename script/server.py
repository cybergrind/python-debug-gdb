#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "fastapi",
#     "gunicorn",
#     "uvicorn",
# ]
# ///

import multiprocessing
import subprocess
import sys

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root():
    return {"status": "ok", "pid": multiprocessing.current_process().pid}


@app.get("/health")
async def health():
    return {"healthy": True}


if __name__ == "__main__":
    subprocess.run(
        [
            sys.executable, "-m", "gunicorn",
            "server:app",
            "--worker-class", "uvicorn.workers.UvicornWorker",
            "--workers", "1",
            "--bind", "0.0.0.0:8000",
            "--access-logfile", "-",
        ],
        cwd="/script",
    )
