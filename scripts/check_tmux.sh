#!/usr/bin/env bash

if [ -z "$TMUX" ]; then
  tmux new-session -s "Run Arm CCA" -d
  tmux send-keys -t "Run Arm CCA" "make run-only" C-m
  tmux attach-session -t "Run Arm CCA"
else
  make run-only
fi
