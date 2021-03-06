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
        _LOG_LEVEL=DEBUG log "$LightCyan" "$@" >&2
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
git_gitdir()
{
    git rev-parse --git-dir
}

git_rev_exist()
{
    git rev-parse --verify --quiet "$1" >/dev/null
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
    git rev-parse --abbrev-ref --symbolic-full-name "$1"@{upstream}

    # OR
    # git_branch_default_upstream_ref "$@" | sed 's/^refs\/heads\///'
}
git_branch_exist()
{
    git_rev_exist "refs/heads/$1"
}

git_head_branch()
{
    git symbolic-ref --short HEAD
}

git_tag_of()
{
    # git describe --exact-match --tags HEAD
    git describe --tags "$1" 2>/dev/null
}

git_commit_date()
{

    # git_commit_date author|commit <ref> [date-format]

    # by default output author-date
    local what_date="%ad"
    if [ "$1" = "commit" ]; then
        # commit date instead of author date
        what_date="%cd"
    fi
    shift

    local ref=$1
    shift

    local fmt="%Y-%m-%d %H:%M:%S"
    if [ "$#" -gt 0 ]; then
        fmt="$1"
    fi
    shift

    git log -n1 --format="$what_date" --date=format:"$fmt" "$ref"
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

git_object_type()
{
    # $0 ref|hash
    # output "commit", "tree" etc
    git cat-file -t "$@" 2>/dev/null
}
git_object_add_by_commit_path()
{
    # add an blob or tree object to target_path in index
    # the object to add is specified by commit and path
    local target_path="$1"
    local src_commit="$2"
    local src_path="$3"

    local src_dir="$(dirname "$src_path")/"
    local src_name="$(basename "$src_path")"
    local src_treeish="$(git rev-parse "$src_commit:$src_dir")"

    git_object_add_by_tree_name "$target_path" "$src_treeish" "$src_name"

}
git_object_add_by_tree_name()
{
    # add an blob or tree object to target_path in index
    local target_path="$1"
    local src_treeish="$2"
    local src_name="$3"

    dd "arg: target_path: ($target_path) src_treeish: ($src_treeish) src_name: ($src_name)"

    local target_dir="$(dirname $target_path)/"
    local target_fn="$(basename $target_path)"
    local treeish

    if [ -z "$src_name" ] || [ "$src_name" = "." ] || [ "$src_name" = "./" ]; then
        treeish="$src_treeish"
    else
        treeish=$(git ls-tree "$src_treeish" "$src_name" | awk '{print $3}')

        if [ -z "$treeish" ]; then
            die "source treeish not found: in tree: ($src_treeish) name: ($src_name)"
        fi
    fi

    dd "hash of object to add is: $treeish"

    if [ "$(git_object_type $treeish)" = "blob" ]; then
        # the treeish imported is a file, not a dir
        # first create a wrapper tree or replace its containing tree

        dd "object to add is blob"

        local dir_treeish
        local target_dir_treeish="$(git rev-parse "HEAD:$target_dir")"
        if [ -n "target_dir_treeish" ]; then
            dir_treeish="$(git rev-parse "HEAD:$target_dir")"
            dd "target dir presents: $target_dir"

        else
            dd "target dir absent"
            dir_treeish=""
        fi

        treeish=$(git_tree_add_blob "$dir_treeish" "$target_fn" $src_treeish $src_name) || die create wrapper treeish
        target_path="$target_dir"

        dd "wrapper treeish: $treeish"
        dd "target_path set to: $target_path"
    else
        dd "object to add is tree"
    fi

    git_treeish_add_to_prefix "$target_path" "$treeish"
}

git_treeish_add_to_prefix()
{
    local target_path="$1"
    local treeish="$2"

    dd treeish content:
    git ls-tree $treeish

    git rm "$target_path" -r --cached || dd removing target "$target_path"

    if [ "$target_path" = "./" ]; then
        git read-tree "$treeish" \
            || die "read-tree $target_path $treeish"
    else
        git read-tree --prefix="$target_path" "$treeish" \
            || die "read-tree $target_path $treeish"
    fi
}

git_tree_add_tree()
{
    # output new tree hash in stdout
    # treeish can be empty
    local treeish="$1"
    local target_fn="$2"
    local item_hash="$3"
    local item_name="$4"

    {
        if [ -n "$treeish" ]; then
            git ls-tree "$treeish" \
                | fgrep -v "	$item_name"
        fi

        cat "040000 tree $item_hash	$target_fn"
    } | git mktree
}
git_tree_add_blob()
{
    # output new tree hash in stdout
    # treeish can be empty
    local treeish="$1"
    local target_fn="$2"
    local blob_treeish="$3"
    local blob_name="$4"

    {
        if [ -n "$treeish" ]; then
            git ls-tree "$treeish" \
                | fgrep -v "	$target_fn"
        fi

        git ls-tree "$blob_treeish" "$blob_name" \
            | awk -v target_fn="$target_fn" -F"	" '{print $1"	"target_fn}'
    } | git mktree
}

git_workdir_save()
{
    local index_hash=$(git write-tree)

    # add modified file to index and read index tree
    git add -u
    local working_hash=$(git write-tree)

    # restore index tree
    git read-tree $index_hash

    echo $index_hash $working_hash
}
git_workdir_load()
{
    local index_hash=$1
    local working_hash=$2

    git_object_type $index_hash || die "invalid index hash: $index_hash"
    git_object_type $working_hash || die "invalid workdir hash: $working_hash"

    # First create a temp commit to restore working tree.
    #
    # git-read-index to index and git-reset does not work because deleted file in
    # index does not apply to working tree.
    #
    # But there is an issue with this:
    #   git checkout --orphan br
    #   git_workdir_load
    # would fails, because ORIG_HEAD is not a commit.

    local working_commit=$(echo "x" | git commit-tree $working_hash) || die get working commit
    git reset --hard $working_commit || die reset to tmp commit
    git reset --soft ORIG_HEAD || die reset to ORIG_HEAD
    git read-tree $index_hash || die "load saved index tree from $index_hash"
}
git_workdir_is_clean()
{
    local untracked="$1"
    if [ "$untracked" == "untracked" ]; then
        [ -z "$(git status --porcelain)" ]
    else
        [ -z "$(git status --porcelain --untracked-files=no)" ]
    fi
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
    # Usage:
    #
    #   diff working tree with HEAD:
    #       git_diff_ln_new HEAD -- <fn>
    #
    #   diff working tree with staged:
    #       git_diff_ln_new -- <fn>
    #
    #   diff staged(cached) with HEAD:
    #       git_diff_ln_new --cached -- <fn>
    #
    # in git-diff output:
    # for add lines:
    # @@ -53 +72,8
    #
    # for remove lines:
    # @@ -155 +179,0

    git diff -U0 "$@" \
        | grep '^@@' \
        | awk '{

    # @@ -155 +179,0
    # $1 $2   $3

    l = $3
    gsub("^+", "", l)

    # add default offset: ",1"
    split(l",1", x, ",")

    # inclusive line range:
    x[2] = x[1] + x[2] - 1

    # line remove format: @@ -155, +179,0
    # do need to output line range for removed.
    if (x[2] >= x[1]) {
        print x[1] " " x[2]
    }

}'
}

# test:

# # file to root
# git reset --hard HEAD
# git_object_add_by_commit_path a HEAD dist/shlib.sh
# git status
# # dir to root
# git reset --hard HEAD
# git_object_add_by_commit_path a HEAD dist
# git status
# # file to folder
# git reset --hard HEAD
# git_object_add_by_commit_path a/b/c HEAD dist/shlib.sh
# git status
# # dir to folder
# git reset --hard HEAD
# git_object_add_by_commit_path a/b/c HEAD dist
# git status
