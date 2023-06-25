#
# * Auto launch tmux when zsh terminal is launched locally
# * If a session exists, attach to that session
# * If session does not exist, create a new session
#

if [[
    -z "$TMUX" &&
    -z "$SSH_TTY" &&
    "$TERM_PROGRAM" != "vscode"
   ]]; then
  if tmux has-session 2> /dev/null; then
    tmux attach-session -d
  else
    tmux new-session -s $(uname -n)
  fi
fi

