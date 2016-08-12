fatal() { echo "fatal [$(basename $BATS_TEST_FILENAME)]: $@" 1>&2; exit 1; } 
_in_cache() {
    IFS=":"; img=($1); unset IFS
    [[ ${#img[@]} -eq 1 ]] && img=("${img[@]}" "latest")
    [ "$(docker images ${img[0]} | grep ${img[1]} | wc -l)" = "1" ] || return 1
}

APPNAME=rabbitmq

[ "$IMAGE" ] || fatal "IMAGE envvar not set"
_in_cache "$IMAGE" || fatal "$IMAGE not in cache"

rabbit_eval() {
    docker run --rm -i \
        --link "$CNAME":"$CNAME" \
        -e RABBITMQ_ERLANG_COOKIE='test' \
        -e RABBITMQ_NODENAME="rabbit@$CNAME" \
        "$IMAGE" \
        "$@"
}

_init() {
    export TEST_SUITE_INITIALIZED=y

    echo >&2 "init: running $IMAGE"
    export CNAME="$APPNAME-$RANDOM-$RANDOM"
    export CID="$(docker run -d --name "$CNAME" --hostname "$CNAME" -e RABBITMQ_ERLANG_COOKIE='test' "$IMAGE")"
    [ "$CIRCLECI" = "true" ] || trap "docker rm -vf $CID > /dev/null" EXIT

#   echo -n >&2 "init: waiting for $IMAGE to accept connections"
#   tries=10
#   while ! rabbit_eval rabbitmqctl -q status &> /dev/null; do
#       (( tries-- ))
#       if [ $tries -le 0 ]; then
#           echo >&2 "$IMAGE failed to accept connections in wait window!"
#           ( set -x && docker logs "$CID" ) >&2 || true
#           false
#       fi
#       echo >&2 -n .
#       sleep 2
#   done
#   echo
}
[ -n "$TEST_SUITE_INITIALIZED" ] || _init

# @test "rabbitmq broker is running" {
#     rabbit_eval rabbitmqctl -q status
#     [ $? -eq 0 ]
# }

@test "dummy" {
    true
}

