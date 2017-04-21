#!/bin/sh

source shlib_log.sh

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

git_commit_copy()
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

git_objetct_type()
{
    # $0 ref|hash
    # output "commit", "tree" etc
    git cat-file -t "$@" 2>/dev/null
}

git_copy_commit()
{
    git_commit_copy "$@"
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
