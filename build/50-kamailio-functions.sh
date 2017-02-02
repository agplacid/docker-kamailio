function kamailio::get-child-procs {
    expr $(nproc) / 2 + 2
}

function kamailio::get-loglevel {
    local key="$1"
    local loglevel_map
    readonly -A loglevel_map=(
        [debug]='L_DBG'
        [info]='L_INFO'
        [notice]='L_NOTICE'
        [warn]='L_WARN'
        [error]='L_ERR'
        [critical]='L_CRIT'
        [critical2]='L_CRIT2'
        [bug]='L_BUG'
        [alert]='L_ALERT')
    echo "${loglevel_map[${key,,}]}"
}
