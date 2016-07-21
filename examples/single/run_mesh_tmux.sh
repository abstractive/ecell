#!/bin/bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

startup_notice='Look at the files in log/ for output. '\
'You should also be able to visit http://localhost:4567 '\
'once the web server launches.'

tmux new -d "echo '$startup_notice' && ruby -e sleep" \; \
	new-window -d './start_piece.rb monitor' \; \
	new-window -d 'sleep 2 && ./start_piece.rb webstack' \; \
	new-window -d 'sleep 2 && ./start_piece.rb process' \; \
	new-window -d 'sleep 4 && ./start_piece.rb events' \; \
	new-window -d 'sleep 4 && ./start_piece.rb tasks' \; \
	attach

