#!/usr/bin/env bash

if [ -z "$TMUX" ]; then
  echo "You're not in a tmux session."
  tmux new-session
  tmux send-keys -t 0 "cd $1" C-m
  tmux send-keys "make -C $1 run-only" C-m
else
  cd $1
  make run-only
fi
