echo::header "Application Tests for $NAME ..."


echo::test "kamailio connected to rabbitmq-alpha.local"
docker logs $NAME 2>&1 | grep -q 'connection to rabbitmq.local opened'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "local.cfg has correct log level"
docker exec $NAME grep KAZOO_LOG_LEVEL /etc/kamailio/local.cfg | grep -q L_INFO
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "local.cfg has correct hostname"
docker exec $NAME bash -l -c 'grep MY_HOSTNAME /etc/kamailio/local.cfg | grep -q kamailio.valuphone.local'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "local.cfg has correct ip address"
docker exec $NAME bash -l -c '[[ $(grep MY_IP_ADDRESS /etc/kamailio/local.cfg | head -1 | cut -d"!" -f4) == $(get-ipv4) ]]'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi


echo::test "local.cfg has primary amqp uri enabled"
docker exec $NAME bash -l -c 'grep MY_AMQP_URL /etc/kamailio/local.cfg | grep -q ^#!'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "local.cfg has correct primary amqp uri"
docker exec $NAME bash -l -c 'grep MY_AMQP_URL /etc/kamailio/local.cfg | grep -q "kazoo://guest:guest@rabbitmq.local:5672"'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

# echo::test "local.cfg has secondary amqp uri enabled"
# docker exec $NAME bash -l -c 'grep MY_SECONDARY_AMQP_URL /etc/kamailio/local.cfg | grep -q ^#!'
# if (($? == 0)); then
#     echo::success "ok"
# else
#     echo::fail "not ok"
#     exit 1
# fi
#
# echo::test "local.cfg has correct secondary amqp uri"
# docker exec $NAME bash -l -c 'grep MY_SECONDARY_AMQP_URL /etc/kamailio/local.cfg | grep -q "kazoo://guest:guest@rabbitmq-beta.local:5672"'
# if (($? == 0)); then
#     echo::success "ok"
# else
#     echo::fail "not ok"
#     exit 1
# fi

for role in WEBSOCKETS MESSAGE REGISTRAR_SYNC PRESENCE_NOTIFY_SYNC; do
    echo::test "local.cfg has role: $role enabled"
    docker exec $NAME bash -l -c "grep ${role}_ROLE /etc/kamailio/local.cfg | grep -q ^#!"
    if (($? == 0)); then
        echo::success "ok"
    else
        echo::fail "not ok"
        exit 1
    fi
done

# echo::test "dispatcher file has correct freeswitch ip address"
# docker exec $NAME bash -l -c '[[ $(cat /volumes/kamailio/dbtext/dispatcher | tail -n +2 | cut -d":" -f4 | sed "s/\\\\//") == $(dig +short freeswitch) ]]'
# if (($? == 0)); then
#     echo::success "ok"
# else
#     echo::fail "not ok"
#     exit 1
# fi

echo >&2
