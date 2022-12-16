#!/usr/bin/env sh

if which live-server; then
  live-server web
elif which python3; then
  python3 -m http.server --directory web
else
  echo "no web server found"
  exit 1
fi
