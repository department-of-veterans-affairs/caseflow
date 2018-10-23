#!/bin/sh

: ${SLEEP_LENGTH:=5}

wait_for() {
  echo Waiting for $1 to listen on $2...
  while ! nc -z $1 $2; do echo sleeping; sleep $SLEEP_LENGTH; done
  echo Starting NGINX...
  nginx -g "daemon off;"
}

for var in "$@"
do
  host=${var%:*}
  port=${var#*:}
  wait_for $host $port
done