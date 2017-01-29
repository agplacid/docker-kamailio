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

# FIXES

function get-ipv4 {
    local interface="${1:-eth0}"
    if linux::cmd::exists 'ip'; then
        ip -o -f inet addr show $interface | sed 's/.*inet \(.*\)\/.*/\1/'
    elif linux::cmd::exists 'ifconfig'; then
        ifconfig $interface | grep 'inet ' | cut -d':' -f2 | awk '{print $1}'
    elif linux::cmd::exists 'hostname'; then
        hostname -i | head -1
    fi
}

function net::get-mtu {
    local interface="${1:-eth0}"
    if linux::cmd::exists 'ip'; then
        ip -o link show $interface | awk '{print $5}'
    elif linux::cmd::exists 'ifconfig'; then
        ifconfig $interface | grep MTU | awk '{print $5}' | cut -d':' -f2
    fi
}
