#!/bin/sh

clr()
{
    # clr light read blabla

    local black=0
    local white=7
    local red=1
    local green=2
    local brown=3
    local blue=4
    local purple=5
    local cyan=6

    local light=""
    local color=$1
    shift

    if [ "$color" == "light" ]; then
        light="tput bold; "
        color=$1
        shift
    fi

    local code=$(eval 'echo $'$color)
    local cmd="${light}tput setaf $code"
    local color_str="$(eval "$cmd")"

    echo $color_str"$@""$(tput sgr0)"
}

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

