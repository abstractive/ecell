#!/bin/bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

startup_notice='Look at the files in log/ for output. '\
'You should also be able to visit http://localhost:4567 '\
'once the web server launches.'

./start_piece.rb monitor &
sleep 2
./start_piece.rb webstack &
./start_piece.rb process &
sleep 2
./start_piece.rb events &
./start_piece.rb tasks &

echo "$startup_notice"

ruby -e sleep

if [[ -n "$(jobs -p)" ]]; then kill -INT $(jobs -p) && sleep 5; fi
if [[ -n "$(jobs -p)" ]]; then kill -KILL $(jobs -p) && wait; fi

