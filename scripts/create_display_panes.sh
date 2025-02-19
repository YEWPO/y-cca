#!/usr/bin/env bash

tmux new-window -n 'Arm CCA'

tmux split-window -v
tmux split-window -h -t 0
tmux split-window -h -t 1

if [ ! -d $HOME/.tmux ]; then
  tmux send-keys -t 0 'socat -,rawer TCP-LISTEN:54320' C-m
  tmux send-keys -t 1 'socat -,rawer TCP-LISTEN:54321' C-m
  tmux send-keys -t 2 'socat -,rawer TCP-LISTEN:54322' C-m
  tmux send-keys -t 3 'socat -,rawer TCP-LISTEN:54323' C-m
else
  tmux send-keys -t 1 'socat -,rawer TCP-LISTEN:54320' C-m
  tmux send-keys -t 2 'socat -,rawer TCP-LISTEN:54321' C-m
  tmux send-keys -t 3 'socat -,rawer TCP-LISTEN:54322' C-m
  tmux send-keys -t 4 'socat -,rawer TCP-LISTEN:54323' C-m
fi

tmux select-window -l

sleep 2
