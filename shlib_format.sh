#!/bin/sh

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
