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
