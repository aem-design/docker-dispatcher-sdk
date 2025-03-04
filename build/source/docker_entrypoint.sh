#!/bin/sh

function run_docker_entrypoint_d {
  if [ -d "/docker_entrypoint.d" ]; then
    for f in /docker_entrypoint.d/*.sh; do
      echo "Running script ${f}"
      . "$f"
    done
  fi
}

run_docker_entrypoint_d

exec "$@"