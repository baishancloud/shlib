#!/bin/sh

os_detect()
{
    local os
    case $(uname -s) in
        Linux)
            os=linux ;;
        *[bB][sS][dD])
            os=bsd ;;
        Darwin)
            os=mac ;;
        *)
            os=unix ;;
    esac
    echo $os
}
