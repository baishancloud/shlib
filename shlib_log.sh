#!/bin/sh


SHLIB_LOG_VERBOSE=1
SHLIB_LOG_FORMAT='$title $mes'

die()
{
    echo "Failure $@" >&2
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
    shift
    shift

    local mes="$@"
    local NC="$(tput sgr0)"

    if [ -t 1 ]; then
        title="${color}${title}${NC}"
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
        log "$LightCyan" "$@"
    fi
}
info()
{
    local Brown="$(tput setaf 3)"
    _LOG_LEVEL=INFO log "$Brown" "$@"
}
ok() {
    local Green="$(tput setaf 2)"
    _LOG_LEVEL=OK log "${Green}" "$@"
}
err() {
    local Red="$(tput setaf 1)"
    _LOG_LEVEL=ERR log "${Red}" "$@"
}

SHLIB_LOG_FORMAT='$(date) $title $mes'
log "$(tput setaf 3)" title mes mes2
