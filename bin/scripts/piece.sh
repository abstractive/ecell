#!/bin/bash

cd `export ECELL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $ECELL`

if [ $# -eq 0 ]
  then
    echo "No piece or action supplied."
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
  echo "Inappropriate piece supplied: $1."
  echo "Available pieces: hostmaster, monitor, process, webstack, events, tasks"
  exit 1
esac

case "$2" in
'run'|'start'|'restart'|'stop'|'console'|'errors'|'flush'|'pry'|'kill')
  exit 0
  ;;
esac

echo "Inappropriate action supplied."
echo "Available pieces: run, start, restart, stop, console, errors, flush, pry."
exit 1

