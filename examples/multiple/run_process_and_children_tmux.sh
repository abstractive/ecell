#!/bin/bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

tmux new -d "./start_piece.rb process $*" \; \
	new-window -d "sleep 2 && ./start_piece.rb events $*" \; \
	new-window -d "sleep 2 && ./start_piece.rb tasks $*" \; \
	attach

