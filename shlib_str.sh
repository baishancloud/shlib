#!/bin/sh

fn_match()
{
    # $0 a.txt *.txt
    case "$1" in
        $2)
            return 0
            ;;
    esac
    return 1
}
