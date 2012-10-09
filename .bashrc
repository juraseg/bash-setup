# ~/.bashrc: executed by bash(1) for non-login shells. see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
 
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history
export HISTCONTROL=ignoreboth:erasedups
# set history length
HISTFILESIZE=1000000000
HISTSIZE=1000000

# append to the history file, don't overwrite it
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry (allows easy re-editing of multi-line commands)
shopt -s cmdhist

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# setup color variables
color_is_on=
color_red=
color_green=
color_yellow=
color_blue=
color_white=
color_gray=
color_bg_red=
color_off=
color_user=
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_is_on=true
	color_red="\[$(/usr/bin/tput setaf 1)\]"
	color_green="\[$(/usr/bin/tput setaf 2)\]"
	color_yellow="\[$(/usr/bin/tput setaf 3)\]"
	color_blue="\[$(/usr/bin/tput setaf 6)\]"
	color_white="\[$(/usr/bin/tput setaf 7)\]"
	color_gray="\[$(/usr/bin/tput setaf 8)\]"
	color_off="\[$(/usr/bin/tput sgr0)\]"

	color_error="$(/usr/bin/tput setab 1)$(/usr/bin/tput setaf 7)"
	color_error_off="$(/usr/bin/tput sgr0)"

	# set user color
	case `id -u` in
		0) color_user=$color_red ;;
		*) color_user=$color_green ;;
	esac
fi

# get git status
function parse_git_status {
    # clear git variables
    GIT_BRANCH=
    GIT_DIRTY=

    # exit if no git found in system
    local GIT_BIN=$(which git 2>/dev/null)
    [[ -z $GIT_BIN ]] && return

    # check we are in git repo
    local CUR_DIR=$PWD
    while [ ! -d ${CUR_DIR}/.git ] && [ ! $CUR_DIR = "/" ]; do CUR_DIR=${CUR_DIR%/*}; done
    [[ ! -d ${CUR_DIR}/.git ]] && return

    # 'git repo for dotfiles' fix: show git status only in home dir and other git repos
    [[ $CUR_DIR == $HOME ]] && [[ $PWD != $HOME ]] && return

    # get git branch
    GIT_BRANCH=$($GIT_BIN symbolic-ref HEAD 2>/dev/null)
    [[ -z $GIT_BRANCH ]] && return
    GIT_BRANCH=${GIT_BRANCH#refs/heads/}

    # get git status
    local GIT_STATUS=$($GIT_BIN status --porcelain 2>/dev/null)
    [[ -n $GIT_STATUS ]] && GIT_DIRTY=true
}

# get hg status
function parse_hg_status {
    # clear hg variables
    HG_BRANCH=
    HG_DIRTY=

    # exit if no hg found in system
    local HG_BIN=$(which hg 2>/dev/null)
    [[ -z $HG_BIN ]] && return

    # check we are in hg repo
    local CUR_DIR=$PWD
    while [ ! -d ${CUR_DIR}/.hg ] && [ ! $CUR_DIR = "/" ]; do CUR_DIR=${CUR_DIR%/*}; done
    [[ ! -d ${CUR_DIR}/.hg ]] && return

    # 'hg repo for dotfiles' fix: show hg status only in home dir and other hg repos
    [[ $CUR_DIR == $HOME ]] && [[ $PWD != $HOME ]] && return

    # get hg branch
    HG_BRANCH=$($HG_BIN branch 2>/dev/null)
    [[ -z $HG_BRANCH ]] && return

    # get hg status
    local HG_STATUS=$($HG_BIN status -amr 2>/dev/null)
    [[ -n $HG_STATUS ]] && HG_DIRTY=true
}

function prompt_command {
    # get cursor position and add new line if we're not in first column
    exec < /dev/tty
    local OLDSTTY=$(stty -g)
    stty raw -echo min 0
    echo -en "\033[6n" > /dev/tty && read -sdR CURPOS
    stty $OLDSTTY
    [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}↵${color_error_off}"

    local PS1_GIT=
    local PS1_HG=
    local PS1_VENV=

    local PWDNAME=$PWD

    # beautify working firectory name
    if [ $HOME == $PWD ]; then
        PWDNAME="~"
    elif [ $HOME ==  ${PWD:0:${#HOME}} ]; then
        PWDNAME="~${PWD:${#HOME}}"
    fi

    ## parse git status and get git variables
    #parse_git_status
    ## parse hg status and get hg variables
    #parse_hg_status

    ## build b/w prompt for git
    #[[ ! -z $GIT_BRANCH ]] && PS1_GIT=" (git: ${GIT_BRANCH})"
    ## build b/w prompt for hg
    #[[ ! -z $HG_BRANCH ]] && PS1_HG=" (hg: ${HG_BRANCH})"

    [[ ! -z $VIRTUAL_ENV ]] && PS1_VENV=" (venv: ${VIRTUAL_ENV#$WORKON_HOME})"

    local color_user=
    if $color_is_on; then
        # set user color
        case `id -u` in
            0) color_user=$color_red ;;
            *) color_user=$color_green ;;
        esac

        # build git status for prompt
        #if [ ! -z $GIT_BRANCH ]; then
            #if [ -z $GIT_DIRTY ]; then
                #PS1_GIT=" (git: ${color_green}${GIT_BRANCH}${color_off})"
            #else
                #PS1_GIT=" (git: ${color_red}${GIT_BRANCH}${color_off})"
            #fi
        #fi

        # build hg status for prompt
        #if [ ! -z $HG_BRANCH ]; then
            #if [ -z $HG_DIRTY ]; then
                #PS1_HG=" (hg: ${color_green}${HG_BRANCH}${color_off})"
            #else
                #PS1_HG=" (hg: ${color_red}${HG_BRANCH}${color_off})"
            #fi
        #fi
        # build python venv status for prompt
        [[ ! -z $VIRTUAL_ENV ]] && PS1_VENV=" (venv: ${color_blue}${VIRTUAL_ENV#$WORKON_HOME}${color_off})"
    fi

    #PS1="${color_user}${USER}${color_off}@${color_yellow}${HOSTNAME}${color_off}:${color_white}${PWDNAME}${color_off}${PS1_GIT}${PS1_HG}${PS1_VENV} ${FILL} ->\n"
    PS1="${color_user}${USER}${color_off}@${color_yellow}${HOSTNAME}${color_off}:${color_white}${PWDNAME}${color_off}${PS1_VENV} ${FILL} ->\n"
}
PROMPT_COMMAND=prompt_command

export VIRTUAL_ENV_DISABLE_PROMPT=1
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh

# Update python path
[[ -d "/usr/local/lib/python2.7/site-packages" ]] && export PYTHONPATH="/usr/local/lib/python2.7/site-packages:$PYTHONPATH"

# bash aliases
if [ -f ~/.bash_aliases ]; then
	source ~/.bash_aliases
fi

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

# this is for delete words by ^W
tty -s && stty werase ^- 2>/dev/null

set -o vi
