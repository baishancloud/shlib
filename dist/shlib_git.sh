#!/bin/sh



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
git_is_merge()
{
    test $(git cat-file -p "$1" | grep "^parent " | wc -l) -gt 1
}
git_parents()
{
    git rev-list --parents -n 1 ${1-HEAD} | { read self parents; echo $parents; }
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
git_tree_hash()
{
    git rev-parse "$1^{tree}"
}
git_ver()
{
    local git_version=$(git --version | awk '{print $NF}')
    local git_version_1=${git_version%%.*}
    local git_version_2=${git_version#*.}
    git_version_2=${git_version_2%%.*}

    printf "%03d%03d" $git_version_1 $git_version_2
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

git_copy_commit()
{
    # We're going to set some environment vars here, so
    # do it in a subshell to get rid of them safely later
    dd copy_commit "{$1}" "{$2}" "{$3}"
    git log -1 --pretty=format:'%an%n%ae%n%ad%n%cn%n%ce%n%cd%n%s%n%n%b' "$1" |
    (
    read GIT_AUTHOR_NAME
    read GIT_AUTHOR_EMAIL
    read GIT_AUTHOR_DATE
    read GIT_COMMITTER_NAME
    read GIT_COMMITTER_EMAIL
    read GIT_COMMITTER_DATE
    export  GIT_AUTHOR_NAME \
        GIT_AUTHOR_EMAIL \
        GIT_AUTHOR_DATE \
        GIT_COMMITTER_NAME \
        GIT_COMMITTER_EMAIL \
        GIT_COMMITTER_DATE

    # (echo -n "$annotate"; cat ) |

    git commit-tree "$2" $3  # reads the rest of stdin
    ) || die "Can't copy commit $1"
}

git_diff_ln_new()
{
    # output changed line number of a file: <from> <end>; inclusive:
    # 27 28
    # 307 309
    # 350 350
    #
    # add lines:
    # @@ -53 +72,8
    # remove lines:
    # @@ -155 +179,0

    git diff -U0 "$@" \
        | grep '^@@' \
        | awk '{
    l=$3
    gsub("^+", "", l)
    split(l",1", x, ",")

    # inclusive line range: 
    x[2]=x[1]+x[2]-1

    # line remove: @@ -155, +179,0
    if (x[2] >= x[1]) {
        print x[1] " " x[2]
    }

}'
}
