#!/bin/bash

cd `export ECELL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $ECELL`

PID=`./bin/scripts/pid.sh $1`
if [ -n "$PID" ]
then
  echo -e "ECell[$1] STOPPING [ `date` ] * * * * * * * * * * * * * * * * * *" >> logs/$1-errors.log
  kill -2 $PID 2> /dev/null
else
  echo -e "\nECell[$1] Already shutdown."
  exit 0
fi

max=10
PID=`./bin/scripts/pid.sh $1`
if [ -n "$PID" ]
then
  printf "ECell[$1] Killing within $max seconds..."
  for i in 1 2 3 4 5 6 7 8 9 10
  do
    sleep 1
    PID=`./bin/scripts/pid.sh $1`
    if [ -z "$PID" ]
    then
      echo -e "\nECell[$1] Shut itself down."
      exit 0
    fi
    printf " $i"
  done
fi

./bin/scripts/kill.sh $1

