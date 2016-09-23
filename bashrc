#!bash
export ENV_HOME=/usr/local/env/${SUDO_USER:-$USER}
export INPUTRC=$ENV_HOME/inputrc
export PATH=$HOME/bin:$ENV_HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
if [ -x $ENV_HOME/bin/editor ]
then
    export EDITOR=$ENV_HOME/bin/editor
else
    export EDITOR=vi
fi

if [ -d $ENV_HOME/lib ]
then
   export RUBYLIB=$ENV_HOME/lib:$RUBYLIB
   export PERLLIB=$ENV_HOME/lib:$PERLLIB
   export PYTHONPATH=$ENV_HOME/lib:$PYTHONPATH
fi

SOURCE_PATH=true
SOURCE_PROMPT=true
SOURCE_FUNCTIONS=true
SOURCE_ALIASES=true
SET_TZ=true

source_if_set() {
    local f ff var="$1" file="$2"

    if [ -n "$var" ]
    then
       for f in {"${ENV_HOME}"/,~/.}"$file"
       do   
           if [ -f "$f" ]
           then 
               . "$f"
           elif [ -d "$f" ]
           then
               for ff in "$f"/*
               do
                   . "$ff"
               done
           fi
       done
    fi
}

source_if_set "$HOSTNAME" bash_hosts/"$HOSTNAME"
source_if_set "$SET_TZ" bash_tz
source_if_set "$SOURCE_PATH" bash_path
source_if_set "$SOURCE_FUNCTIONS" bash_functions
source_if_set "$SOURCE_ALIASES" bash_aliases
source_if_set "$SOURCE_PROMPT" bash_prompt

set -o vi

alias r='. $ENV_HOME/bashrc'

export gerrit=git+ssh://review:29418
