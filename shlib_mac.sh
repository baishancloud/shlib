#!/bin/sh

source shlib_log.sh
source shlib_sys.sh

mac_ac_power_connection()
{
    #  Connected: (Yes|No)
    system_profiler SPPowerDataType \
        | sed '1,/^ *AC Charger Information:/d' \
        | grep Connected:
}


mac_power()
{

    # $0 is-battery          exit code 0 if using battery.
    # $0 is-ac-power         exit code 0 if using ac power.

    local cmd="$1"
    local os=$(os_detect)

    if [ "$os" != "mac" ]; then
        err "not mac but: $os"
        return 1
    fi

    case $cmd in

        is-battery)
            mac_ac_power_connection | grep -q No
            ;;

        is-ac-power)
            mac_ac_power_connection | grep -q Yes
            ;;

        *)
            err "invalid cmd: $cmd"
            return 1
            ;;
    esac
}
