FROM python:3.13.12-bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends gdb procps curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Pre-install Python dependencies so they're baked into the image
RUN uv pip install --system fastapi gunicorn uvicorn

COPY script/ /script/
RUN chmod +x /script/*.sh /script/*.py

WORKDIR /script
CMD ["python", "server.py"]
