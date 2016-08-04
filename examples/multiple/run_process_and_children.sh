#!/bin/bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

./start_piece.rb process "$@" &
sleep 2
./start_piece.rb events "$@" &
./start_piece.rb tasks "$@" &

ruby -e sleep

if [[ -n "$(jobs -p)" ]]; then kill -INT $(jobs -p) && sleep 5; fi
if [[ -n "$(jobs -p)" ]]; then kill -KILL $(jobs -p) && wait; fi

