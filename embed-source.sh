#!/bin/sh

shlib_embed_source()
{
    local path="$1"
    local dst_dir="$2"
    local sources=

    mkdir -p "$(dirname "$dst_dir/$path")"
    cp "$path" "$dst_dir/$path"
    path="$dst_dir/$path"

    while ``; do
        sources="$(awk -f find-source.awk $path)"
        echo "embed: ($sources) into $path" >&2;

        if [ -z "$sources" ]; then
            break
        fi

        awk -f embed-source.awk "$path" >"$path.tmp"
        mv "$path.tmp" "$path"
    done

}

shlib_embed_source "$@"
