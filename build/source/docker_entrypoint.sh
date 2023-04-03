#!/bin/sh

echo "Starting [$@]"

function run_docker_entrypoint_d {
  if [ -d "/docker_entrypoint.d" ]; then
    for f in /docker_entrypoint.d/*.sh; do
      echo "Running script ${f}"
      . "$f"
    done
  fi
}
echo "Run scripts"
run_docker_entrypoint_d

# is $@ is empty, run httpd-foreground
if [ -z "$@" ]; then
  exec /usr/sbin/httpd-foreground
else
  exec "$@"
fi
