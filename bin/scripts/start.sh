#!/bin/bash

if ! [ $# -gt 0 ];
then
  echo "No ecell instance passed in."
  exit 1
fi


cd `export ECELL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $ECELL`

PID=`./bin/scripts/pid.sh $1`

if [ -n "$PID" ]
then
  echo "ECell[$1] still seems to be running."
  ./bin/scripts/kill.sh $1
fi

echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" >> logs/$1-console.log
echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" >> logs/$1-console.log
echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" >> logs/$1-console.log
echo "" > logs/$1-console.log
echo "" > logs/$1-errors.log
echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nECell[$1] STARTING [ `date` ]" >> logs/$1-errors.log

command="bundle exec ruby bin/start_piece.rb $1"

if [ $# -eq 2 ]
then
  case "$2" in
    'pry')
      #de trap "./bin/scripts/stop.sh $1" INT
      echo "Opening PRY session at start."
      $command pry 2>> logs/$1-errors.log
      exit 0
      ;;
    *)
      echo "Unexpected parameter: $2"
      exit 1
      ;;
  esac
fi

$command 2>> logs/$1-errors.log >> logs/$1-console.log &

