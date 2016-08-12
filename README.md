# tklx/rabbitmq - Distributed task queue
[![CircleCI](https://circleci.com/gh/tklx/rabbitmq.svg?style=shield)](https://circleci.com/gh/tklx/rabbitmq)

RabbitMQ is open source message broker software (sometimes called message-oriented middleware) that implements the Advanced Message Queuing Protocol (AMQP). The RabbitMQ server is written in the Erlang programming language and is built on the Open Telecom Platform framework for clustering and failover. Client libraries to interface with the broker are available for all major programming languages.

## Features

- Based on the super slim [tklx/base][base] (Debian GNU/Linux).
- RabbitMQ installed directly from Debian.
- Uses [tini][tini] for zombie reaping and signal forwarding.
- Includes `EXPOSE 4369 5671 5672 15671 15672 25672`, so standard container linking will make it automatically available to the linked containers.
- Configured to forward access and error logs to docker log collector.

## Usage

### Running the daemon

RabbitMQ node names (which are used to address cluster members) are based on hostnames. For reliable results, supplying an explicit hostname to `docker run` is recommended.

```console
$ docker run -d --hostname my-rabbit --name some-rabbit tklx/rabbitmq
```

### Erlang Cookie

To set a consistent Erlang cookie (useful for [clustering][rabbitmq-clustering] and remote `rabbitmqctl` access), use `RABBITMQ_ERLANG_COOKIE`:

```console
$ docker run -d --hostname my-rabbit --name some-rabbit -e RABBITMQ_ERLANG_COOKIE='secret cookie here' tklx/rabbitmq
```

This can then be used from a separate instance to connect:

```console
$ docker run -it --rm --link some-rabbit:my-rabbit -e RABBITMQ_ERLANG_COOKIE='secret cookie here' tklx/rabbitmq bash
root@ce19ca4a0929:/# rabbitmqctl -n rabbit@my-rabbit list_users
Listing users ...
guest   [administrator]
```

Alternatively, one can also use `RABBITMQ_NODENAME` to make repeated `rabbitmqctl` invocations simpler:

```console
$ docker run -it --rm --link some-rabbit:my-rabbit -e RABBITMQ_ERLANG_COOKIE='secret cookie here' -e RABBITMQ_NODENAME=rabbit@my-rabbit tklx/rabbitmq bash
root@ce19ca4a0929:/# rabbitmqctl list_users
Listing users ...
guest   [administrator]
```

### Management Plugin

The [management plugin][rabbitmq-management] can be enabled with `RABBITMQ_MANAGEMENT=1`. The default port is 15672 and the default username/password is `guest`/`guest`.

```console
$ docker run -d --hostname my-rabbit --name some-rabbit -e RABBITMQ_MANAGEMENT=1 tklx/rabbitmq
```

You can access it by visiting `http://container-ip:15672` or exposing the port outside the host:

```console
$ docker run -d --hostname my-rabbit --name some-rabbit -p 8080:15672 -e RABBITMQ_MANAGEMENT=1 tklx/rabbitmq
```

### Setting default user and password

If you wish to change the default username and password of `guest` / `guest`, you can do so with the `RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS` environmental variables:

```console
$ docker run -d --hostname my-rabbit --name some-rabbit -e RABBITMQ_MANAGEMENT=1 -e RABBITMQ_DEFAULT_USER=user -e RABBITMQ_DEFAULT_PASS=password tklx/rabbitmq
```

### Setting default vhost

If you wish to change the default vhost, you can do so with the `RABBITMQ_DEFAULT_VHOST` environmental variable:

```console
$ docker run -d --hostname my-rabbit --name some-rabbit -e RABBITMQ_DEFAULT_VHOST=my_vhost tklx/rabbitmq
```

### Enabling HiPE

See the [RabbitMQ "Configuration"][rabbitmq-config] for more information about various configuration options.

For enabling the HiPE compiler on startup, set `RABBITMQ_HIPE_COMPILE=1`. According to the official documentation:

> Set to true to precompile parts of RabbitMQ with HiPE, a just-in-time compiler for Erlang. This will increase server throughput at the cost of increased startup time. You might see 20-50% better performance at the cost of a few minutes delay at startup.

It is therefore important to take that startup delay into consideration when configuring health checks, automated clustering etc.

### Connecting to the broker

```console
$ docker run --name some-app --link some-rabbit:rabbit -d application-that-uses-rabbitmq
```

### Tips

To disable startup and/or error logs forwarding to the docker log
collector, the following environmental variables can be set:
``NOSTDOUTREDIR`` ``NOSTDERRREDIR``.

## Automated builds

The [Docker image](https://hub.docker.com/r/tklx/rabbitmq/) is built, tested and pushed by [CircleCI](https://circleci.com/gh/tklx/rabbitmq) from source hosted on [GitHub](https://github.com/tklx/rabbitmq).

* Tag: ``x.y.z`` refers to a [release](https://github.com/tklx/rabbitmq/releases) (recommended).
* Tag: ``latest`` refers to the master branch.

## Status

Currently on major version zero (0.y.z). Per [Semantic Versioning][semver],
major version zero is for initial development, and should not be considered
stable. Anything may change at any time.

## Issue Tracker

TKLX uses a central [issue tracker][tracker] on GitHub for reporting and
tracking of bugs, issues and feature requests.

[rabbitmq]: https://www.rabbitmq.com/
[rabbitmq-clustering]: https://www.rabbitmq.com/clustering.html
[rabbitmq-management]: https://www.rabbitmq.com/management.html
[rabbitmq-config]: http://www.rabbitmq.com/configure.html#config-items
[base]: https://github.com/tklx/base
[tini]: https://github.com/krallin/tini
[semver]: http://semver.org/
[tracker]: https://github.com/tklx/tracker/issues
