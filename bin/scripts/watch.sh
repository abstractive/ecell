#!/bin/bash

cd `export ECELL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $ECELL`

if [ -n ]
then
  touch logs/$1-$2.log
fi

tail -f logs/$1-$2.log

