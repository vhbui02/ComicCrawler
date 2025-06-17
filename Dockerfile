FROM python:slim-bullseye
# Create user, setup app directory, and install dependencies in one layer
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential gcc && \
  groupadd -g 1000 python && \
  useradd -r -u 1000 -g python python && \
  mkdir /app && \
  chown python:python /app && \
  python -m venv /app/.venv && \
  /app/.venv/bin/pip install --no-cache-dir comiccrawler && \
  chown -R python:python /app/.venv && \
  rm -rf /var/lib/apt/lists/*
COPY --from=denoland/deno:latest --chown=python:python /deno /usr/local/bin/deno
WORKDIR /app
ENV PATH="/app/.venv/bin:$PATH"
USER 1000
ENTRYPOINT ["comiccrawler"]
CMD ["--help"]