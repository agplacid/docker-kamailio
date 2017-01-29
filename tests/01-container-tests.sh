echo::header "Basic Container Tests for $NAME"

echo::test "Container Up Test"
docker ps | grep -q $NAME
if (($? == 0)); then
    echo::success "$NAME running"
else
    echo::fail "$NAME not running"
    exit 1
fi

if [[ ! -z $LOG_TEST_PATTERN ]]; then
    echo::test "Log Pattern Test"
    docker logs $NAME 2>/dev/null | grep -q "$LOG_TEST_PATTERN"
    if (($? == 0)); then
        echo::success "'$LOG_TEST_PATTERN' found"
    else
        echo::fail "'$LOG_TEST_PATTERN' not found"
        exit 1
    fi
fi

if [[ ! -z $TEST_TCP_PORTS ]]; then
    echo::test "TCP Port Test"
    for item in ${TEST_TCP_PORTS//,/ }; do
        docker exec $NAME bash -l -c "nc -z $BIND_ADDR $item"
        if (($? == 0)); then
            echo::success "$item open"
        else
            echo::fail "$item not open"
            exit 1
        fi
    done
fi

if [[ ! -z $TEST_UDP_PORTS ]]; then
    echo::test "UDP Port Test"
    for item in ${TEST_UDP_PORTS//,/ }; do
        docker exec $NAME bash -l -c "nc -z -u $BIND_ADDR $item"
        if (($? == 0)); then
            echo::success "$item open"
        else
            echo::fail "$item not open"
            exit 1
        fi
    done
fi

if [[ ! -z $TEST_HTTP_URIS ]]; then
    echo::test "URI Reachability Test"
    for item in ${TEST_HTTP_URIS//,/ }; do
        docker exec $NAME bash -l -c "curl -s $item > /dev/null"
        ret=$?
        if (($ret == 0)); then
            echo::success "$item up"
        else
            echo::fail "$item not up.  code: $ret"
            exit 1
        fi
    done
fi
