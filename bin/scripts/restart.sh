#!/bin/bash

cd `export ECELL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $ECELL`

./bin/scripts/stop.sh $1
./bin/scripts/start.sh $1

