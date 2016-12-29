#!/bin/sh

shlib_embed_source()
{
    local path="$1"
    local dst_dir="$2"
    local sources=
    local included=
    local out=

    echo "shlib_embed_source: [$path] [$dst_dir]"

    mkdir -p "$(dirname "$dst_dir/$path")"
    # cp "$path" "$dst_dir/$path"
    # path="$dst_dir/$path"

    sources="$(awk -f find-source.awk $path)"
    echo "embed: ($sources) into $path" >&2;

    if [ -z "$sources" ]; then
        cp $path $dst_dir/$path
        return
    fi

    included=" $sources "

    for _sub in $sources; do
        if [ -f "$dst_dir/$_sub" ]; then
            continue
        else
            out="$(shlib_embed_source $_sub $dst_dir)"
            if [ ! -f "$dst_dir/$_sub" ]; then
                echo fail
                exit 1
            fi
            included="$included $out"
        fi
    done

    awk -f embed-source.awk "$path" >"$dst_dir/$path"

    echo $included
}

shlib_embed_source "$@"
