#!/bin/bash

################################################################################
# Change the values of the prompt_color, GIT_PS1* and ps2_color
# to customize the various colors used in the prompt.
# Use the predifined constants like orange, green, yellow ...
# or use tput.  You can do either
#    GIT_PS1_DIRTY_COLOR=$(tput setaf 208)
# or use the constants
#    GIT_PS1_DIRTY_COLOR=$yellow
################################################################################
git_ps1_set_colors(){

    orange=$(tput setaf 9)
    green=$(tput setaf 2)
    yellow=$(tput setaf 11)
    purple=$(tput setaf 5)
    blue=$(tput setaf 4)
    red=$(tput setaf 1)
    bold=$(tput bold)
    reset_colors=$(tput sgr 0)

    # define variables for prompt colors
    prompt_color=$purple

    # For the display of exit code of previous command
    GIT_PS1_SUCCESS_COLOR=$green
    GIT_PS1_FAILURE_COLOR=$red

    # For the display of the git part
    GIT_PS1_HEADLESS_COLOR=$red
    GIT_PS1_DIRTY_COLOR=$yellow
    GIT_PS1_CLEAN_COLOR=$green

    # Color of PS2 prompt that is used for multiline commands
    ps2_color=$purple
}

################################################################################
# Calculates the time since the last commit and echoes a formatted string
################################################################################
git_time_since_commit() {
    # Lifted from zsh theme dogenpunk
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi
    # Only proceed if there is actually a commit.
    if ! git log -n 1  > /dev/null 2>&1; then
        return
    fi

    last_commit_unix_timestamp=$(git log --pretty=format:'%at' -1 2> /dev/null)
    now_unix_timestamp=$(date +%s)
    seconds_since_last_commit=$(($now_unix_timestamp - $last_commit_unix_timestamp))

    # Totals
    MINUTES=$(($seconds_since_last_commit / 60))
    HOURS=$(($seconds_since_last_commit/3600))

    # Sub-hours and sub-minutes
    seconds_per_day=$((60*60*24))
    DAYS=$(($seconds_since_last_commit / $seconds_per_day))
    SUB_HOURS=$(($HOURS % 24))
    SUB_MINUTES=$(($MINUTES % 60))
    if [ "$DAYS" -gt 5 ] ; then
        echo "${DAYS}days"
    elif [ "$DAYS" -gt 0 ]; then
        echo "${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m"
    elif [ "$HOURS" -gt 0 ]; then
        echo "${HOURS}h${SUB_MINUTES}m"
    else
        echo "${MINUTES}m"
    fi
}


################################################################################
# Sets a bunch of variables that are used to construct the prompt.
#   _git_ps1_in_repo
#   _git_ps1_inside_git_dir
#   _git_ps1_rebase_state
#   _git_ps1_branch
#   _git_ps1_has_untracked
#   _git_ps1_has_unstaged_changes
#   _git_ps1_has_staged_changes
#   _git_ps1_time_since_commit
################################################################################
git_ps1_get_info(){
    # THese three variables would be preceded by the keyword local
    # if this were a bash-only script.
    rebasing=""
    branche=""
    gitdir=$(git rev-parse --git-dir 2>/dev/null)

    if ! [ -z $gitdir ] ; then
        _git_ps1_in_repo=true
    else
        return
    fi

    if [ -f "$gitdir/rebase-merge/interactive" ]; then
        rebasing="|REBASE-i"
        branch="$(cat "$gitdir/rebase-merge/head-name")"
    elif [ -d "$gitdir/rebase-merge" ]; then
        rebasing="|REBASE-m"
        branch="$(cat "$gitdir/rebase-merge/head-name")"
    else
        if [ -d "$gitdir/rebase-apply" ]; then
            if [ -f "$gitdir/rebase-apply/rebasing" ]; then
                rebasing="|REBASE"
            elif [ -f "$gitdir/rebase-apply/applying" ]; then
                rebasing="|AM"
            else
                rebasing="|AM/REBASE"
            fi
        elif [ -f "$gitdir/MERGE_HEAD" ]; then
            rebasing="|MERGING"
        elif [ -f "$gitdir/CHERRY_PICK_HEAD" ]; then
            rebasing="|CHERRY-PICKING"
        elif [ -f "$gitdir/BISECT_LOG" ]; then
            rebasing="|BISECTING"
        fi

        branch="$(git symbolic-ref HEAD 2>/dev/null)"

        if [ -z $branch ] ; then
            detached=yes
            branch="$(
                          case "${GIT_PS1_DESCRIBE_STYLE-}" in
                              (contains)
                                git describe --contains HEAD ;;
                              (branch)
                                git describe --contains --all HEAD ;;
                              (describe)
                                git describe HEAD ;;
                              (* | default)
                                git describe --tags --exact-match HEAD ;;
                          esac 2>/dev/null
                      )" ||

                branch="$(cut -c1-7 "$gitdir/HEAD" 2>/dev/null)..." ||
                branch="unknown"
            branch="($branch)"
        fi
    fi

    if ! [ -z "$(git ls-files $gitdir/.. --others --exclude-standard 2>/dev/null)" ] ; then
        _git_ps1_has_untracked=true
    fi

    if ! git diff --no-ext-diff --quiet --exit-code 2>/dev/null ; then
        _git_ps1_has_unstaged_changes=true
    else
        _git_ps1_has_unstaged_changes=false
    fi
    if ! git diff --staged --no-ext-diff --quiet --exit-code 2>/dev/null ; then
        _git_ps1_has_staged_changes=true
    else
        _git_ps1_has_staged_changes=false
    fi
    _git_ps1_inside_git_dir="$(git rev-parse --is-inside-git-dir 2>/dev/null)"
    _git_ps1_rebase_state=$rebasing
    _git_ps1_branch=${branch##refs/heads/}
    _git_ps1_headless=$detached
    _git_ps1_time_since_commit=$(git_time_since_commit)
}
################################################################################
# Construct the git part of the prompt based on the info acquired by
# git_ps1_get_info and the colors specified by the user in git_ps1_set_colors.
################################################################################
git_ps1(){
    _git_ps1_in_repo=""
    _git_ps1_inside_git_dir=""
    _git_ps1_rebase_state=""
    _git_ps1_branch=""
    _git_ps1_has_untracked=""
    _git_ps1_has_unstaged_changes=""
    _git_ps1_has_staged_changes=""
    _git_ps1_time_since_commit=""

    git_ps1_get_info

    if [ -z $_git_ps1_in_repo ] ; then
        return
    fi

    state=clean
    if ! [ -z $_git_ps1_headless ] ; then
        state=headless
    elif $_git_ps1_has_unstaged_changes ||  $_git_ps1_has_staged_changes ; then
        state=dirty
    else
        state=clean
    fi

    case $state in
        headless) fg_color=$GIT_PS1_HEADLESS_COLOR ;;
        clean) fg_color=$GIT_PS1_CLEAN_COLOR ;;
        dirty) fg_color=$GIT_PS1_DIRTY_COLOR ;;
        *) fg_color=$(tput setaf 3) ;;
    esac

    if ! [ -z $_git_ps1_has_untracked ] ; then
        _git_ps1_untracked="[UNTRACKED FILES]"
	  fi

	  if ! [ -z $_git_ps1_has_staged_changes ] || ! [ -z $_git_ps1_has_unstaged_changes ] ; then
		    time_since_last_commit=" $(git_time_since_commit)"
	  fi

	  if ! [ -z $_git_ps1_in_repo ] ; then
		    echo "\[$fg_color\]($_git_ps1_branch$_git_ps1_rebase_state)$_git_ps1_untracked$time_since_last_commit\[$(tput sgr 0)\]"
	  fi

}

git_pwd() {
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]] ; then
        repo_dir=$(git rev-parse --show-toplevel 2>/dev/null)
        outer=$(basename $repo_dir)
        inner=$(git rev-parse --show-prefix 2>/dev/null)
        echo "${outer}/${inner}"
    else
        echo '\w'
    fi
}
################################################################################
# Different way of making PS1.  We rewrite PS1 right before it is to be
# displayed.  This is way more simple since we don't have to deal with all the
# weird ways that escaping characters can make our life difficult.
################################################################################
make_ps1(){
    previous_exit_code=$?
    if [[ $previous_exit_code == 0 ]] ; then
        previous_exit_code="\[$GIT_PS1_SUCCESS_COLOR\] 0 \[$reset_colors\]"
    else
        previous_exit_code="\[$GIT_PS1_FAILURE_COLOR\] $previous_exit_code \[$reset_colors\]"
    fi

    prompt_start="\[$prompt_color\][\\u@\\h $(git_pwd)\[$reset_colors\]"

    git_part="$(git_ps1)"
    if ! [ -z "$git_part" ] ; then
        git_part=" $git_part\[$reset_colors\]"
    fi

    last_part="\[$prompt_color\]] \$\[$reset_colors\] "

    PS1="$previous_exit_code$prompt_start$git_part$last_part"
}

################################################################################
# 
################################################################################
configure_prompt(){
    # Define colors for making prompt string.
    git_ps1_set_colors

    PS2="\[$ps2_color\] > \[$reset_colors\]"

    # Instead of doing PS1=something, we set PROMPT_COMMAND.
    # and that command will be called to set PS1.
    export PROMPT_COMMAND=make_ps1
}

configure_prompt

