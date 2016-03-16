#!/bin/bash

cd `export EF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"; echo $EF`

./bin/scripts/stop.sh $1
./bin/scripts/start.sh $1
