#!/bin/sh


shlib_init_colors()
{
    Black="$(                   tput setaf 0)"
    BlackBG="$(                 tput setab 0)"
    DarkGrey="$(     tput bold; tput setaf 0)"
    LightGrey="$(               tput setaf 7)"
    LightGreyBG="$(             tput setab 7)"
    White="$(        tput bold; tput setaf 7)"
    Red="$(                     tput setaf 1)"
    RedBG="$(                   tput setab 1)"
    LightRed="$(     tput bold; tput setaf 1)"
    Green="$(                   tput setaf 2)"
    GreenBG="$(                 tput setab 2)"
    LightGreen="$(   tput bold; tput setaf 2)"
    Brown="$(                   tput setaf 3)"
    BrownBG="$(                 tput setab 3)"
    Yellow="$(       tput bold; tput setaf 3)"
    Blue="$(                    tput setaf 4)"
    BlueBG="$(                  tput setab 4)"
    LightBlue="$(    tput bold; tput setaf 4)"
    Purple="$(                  tput setaf 5)"
    PurpleBG="$(                tput setab 5)"
    Pink="$(         tput bold; tput setaf 5)"
    Cyan="$(                    tput setaf 6)"
    CyanBG="$(                  tput setab 6)"
    LightCyan="$(    tput bold; tput setaf 6)"
    NC="$(                      tput sgr0)" # No Color
}

screen_width()
{
    local chr="${1--}"
    chr="${chr:0:1}"

    local width=$(tput cols 2||echo 80)
    width="${COLUMNS:-$width}"

    echo $width
}

hr()
{
    # generate a full screen width horizontal ruler
    local width=$(screen_width)

    printf -vl "%${width}s\n" && echo ${l// /$chr};
}

remove_color()
{
    # remove color control chars from stdin or first argument

    local sed=gsed
    which -s $sed || sed=sed

    local s="$1"
    if [ -z "$s" ]; then
        $sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"
    else
        echo "$s" | remove_color
    fi

}

text_hr()
{
    # generate a full screen width sperator line with text.
    # text_hr "-" "a title"
    # > a title -----------------------------------------
    #
    # variable LR=l|m|r controls alignment

    local chr="$1"
    shift

    local bb="$(echo "$@" | remove_color)"
    local text_len=${#bb}

    local width=$(screen_width)
    let width=width-text_len

    local lr=${LR-m}
    case $lr in
        m)
            let left=width/2
            let right=width-left
            echo "$(printf -vl "%${left}s\n" && echo ${l// /$chr})$@$(printf -vl "%${right}s\n" && echo ${l// /$chr})"
            ;;
        r)

            echo "$(printf -vl "%${width}s\n" && echo ${l// /$chr})$@"
            ;;
        *)
            # l by default
            echo "$@$(printf -vl "%${width}s\n" && echo ${l// /$chr})"
            ;;
    esac

}


SHLIB_LOG_VERBOSE=1
SHLIB_LOG_FORMAT='[$(date +"%Y-%m-%d %H:%M:%S")] $level $title $mes'

die()
{
    err "$@" >&2
    exit 1
}
die_empty()
{
    if test -z "$1"
    then
        shift
        die empty: "$@"
    fi
}

set_verbose()
{
    SHLIB_LOG_VERBOSE=${1-1}
}

log()
{
    local color="$1"
    local title="$2"
    local level="$_LOG_LEVEL"
    shift
    shift

    local mes="$@"
    local NC="$(tput sgr0)"

    if [ -t 1 ]; then
        title="${color}${title}${NC}"
        level="${color}${level}${NC}"
    fi
    eval "echo \"$SHLIB_LOG_FORMAT\""
}
dd()
{
    debug "$@"
}
debug()
{
    if [ ".$SHLIB_LOG_VERBOSE" = ".1" ]; then
        local LightCyan="$(tput bold ; tput setaf 6)"
        _LOG_LEVEL=DEBUG log "$LightCyan" "$@"
    fi
}
info()
{
    local Brown="$(tput setaf 3)"
    _LOG_LEVEL=" INFO" log "$Brown" "$@"
}
ok() {
    local Green="$(tput setaf 2)"
    _LOG_LEVEL="   OK" log "${Green}" "$@"
}
err() {
    local Red="$(tput setaf 1)"
    _LOG_LEVEL="ERROR" log "${Red}" "$@"
}


git_hash()
{
    git rev-parse $1 \
        || die "'git_hash $@'"
}
git_rev_list()
{
    # --parents
    # print parent in this form:
    #     <commit> <parent-1> <parent-2> ..

    git rev-list \
        --reverse \
        --topo-order \
        --default HEAD \
        --simplify-merges \
        "$@" \
        || die "'git rev-list $@'"
}
git_ver()
{
    local git_version=$(git --version | awk '{print $NF}')
    local git_version_1=${git_version%%.*}
    local git_version_2=${git_version#*.}
    git_version_2=${git_version_2%%.*}

    printf "%03d%03d000" $git_version_1 $git_version_2
}
git_working_root()
{
    git rev-parse --show-toplevel
}

git_branch_default_remote()
{
    local branchname=$1
    git config --get branch.${branchname}.remote
}
git_branch_default_upstream_ref()
{
    local branchname=$1
    git config --get branch.${branchname}.merge
}
git_branch_default_upstream()
{
    git_branch_default_upstream_ref "$@" | sed 's/^refs\/heads\///'
}

git_head_branch()
{
    git symbolic-ref --short HEAD
}
