# Login shells: source .bashrc so interactive setup applies here too.
[ -f ~/.bashrc ] && . ~/.bashrc

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# Guarded so it's a no-op on machines without anaconda installed.
if [ -x "/opt/anaconda3/bin/conda" ]; then
  __conda_setup="$('/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    . "/opt/anaconda3/etc/profile.d/conda.sh"
  else
    export PATH="/opt/anaconda3/bin:$PATH"
  fi
  unset __conda_setup
fi
# <<< conda initialize <<<
