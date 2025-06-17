#!/bin/sh

docker run \
  --rm \
  --init \
  --name="comiccrawler" \
  -u="$(id -u)":"$(id -g)" \
  -v="./setting.ini":"/app/setting.ini" \
  -v="./downloads":"/app/downloads" \
  silverbullet069/comiccrawler:latest \
  --profile=/app \
  --dest=/app/downloads \
  "$@"
