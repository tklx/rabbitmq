## Install dependencies

```console
git clone https://github.com/tklx/bats.git
bats/install.sh /usr/local
```

## Run the tests

```console
IMAGE=tklx/rabbitmq bats --tap tests/basics.bats
init: running tklx/rabbitmq
1..1
ok 1 rabbitmq broker is running

