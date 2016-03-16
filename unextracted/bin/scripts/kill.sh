#!/bin/bash

cd `export EF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $EF`

PID=`./bin/scripts/pid.sh $1`

if [ -n "$PID" ]
then
  kill -9 $PID
  echo -e "\n[ $1 ] KILL [ `date` ] $PID" >> logs/$1-errors.log
fi
exit 0
