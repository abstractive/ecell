#!/bin/bash

cd `export EF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $EF`

if [ -n ]
then
  touch logs/$1-$2.log
fi

tail -f logs/$1-$2.log
