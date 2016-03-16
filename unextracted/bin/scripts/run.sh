#!/bin/bash

cd `export EF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $EF`

./bin/scripts/start.sh $1
trap "./bin/scripts/stop.sh $1" INT
./bin/scripts/watch.sh $1 console
