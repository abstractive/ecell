#!/bin/bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

./start_piece.rb process "$@" &
sleep 2
./start_piece.rb events "$@" &
./start_piece.rb tasks "$@" &

ruby -e sleep

jobs="$(jobs -p)"
if [[ -n "$jobs" ]]; then kill -INT $(jobs -p) && wait; fi

