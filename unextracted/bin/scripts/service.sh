#!/bin/bash

cd `export EF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $EF`

if [ $# -eq 0 ]
  then
    echo "No service or action supplied."
    exit 1
fi

if [ $# -eq 1 ]
  then
    echo "No action supplied."
    exit 1
fi

case "$1" in
'hostmaster'|'monitor'|'process'|'webstack'|'events'|'tasks')
  ;;
*)
  echo "Inappropriate service supplied: $1."
  echo "Available services: hostmaster, monitor, process, webstack, events, tasks"
  exit 1
esac

case "$2" in
'run'|'start'|'restart'|'stop'|'console'|'errors'|'flush'|'pry'|'kill')
  exit 0
  ;;
esac

echo "Inappropriate action supplied."
echo "Available services: run, start, restart, stop, console, errors, flush, pry."
exit 1
