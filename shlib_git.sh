#!/bin/sh

source shlib_log.sh

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
