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
        --link "$CNAME":$APPNAME \
        -e RABBITMQ_ERLANG_COOKIE='test' \
        "$IMAGE" \
        "$@"
}

_init() {
    export TEST_SUITE_INITIALIZED=y

    echo >&2 "init: running $IMAGE"
    export CNAME="$APPNAME-$RANDOM-$RANDOM"
    export CID="$(docker run -d --name "$CNAME" --hostname "$APPNAME" -e RABBITMQ_ERLANG_COOKIE='test' "$IMAGE")"
    [ "$CIRCLECI" = "true" ] || trap "docker rm -vf $CID > /dev/null" EXIT
}
[ -n "$TEST_SUITE_INITIALIZED" ] || _init

@test "rabbitmq broker is running" {
    rabbit_eval rabbitmqctl -q -n rabbit@"$APPNAME" status
    [ $? -eq 0 ]
}

