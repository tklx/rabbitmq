FROM tklx/base:0.1.0

RUN set -x \
    # Set up testing (needed until tklx/core is rebased to testing)
    && sed -i 's/jessie/testing/g' /etc/apt/sources.list.d/sources.list \
    && sed -i 's/jessie/testing/g' /etc/apt/sources.list.d/security.sources.list \
    && apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade \
    && apt-clean --aggressive

ARG TINI_VERSION=v0.9.0
RUN set -x \
    && TINI_URL=https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    && TINI_GPGKEY=0527A9B7 \
    && export GNUPGHOME="$(mktemp -d)" \
    && apt-get update && apt-get -y install wget ca-certificates \
    && wget -O /tini ${TINI_URL} \
    && wget -O /tini.asc ${TINI_URL}.asc \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${TINI_GPGKEY} \
    && gpg --verify /tini.asc \
    && chmod +x /tini \
    && rm -r ${GNUPGHOME} /tini.asc \
    && apt-get purge -y --auto-remove wget ca-certificates \
    && apt-clean --aggressive


ARG NEED_USER='rabbitmq'
ARG NEED_HOME='/var/lib/rabbitmq'

ARG USER_KEEP="root\|mail\|_apt"
ARG GROUP_KEEP="adm\|tty\|mail\|shadow\|utmp\|staff\|root\|nogroup"

# Tighten security
RUN set -x \
    # Set up needed user
    && if [ -n "${NEED_USER}" ]; then \
	NEED_SHELL=${NEED_SHELL:-/usr/sbin/nologin}; \
	NEED_HOME=${NEED_HOME:-/dev/null}; \
        if id $NEED_USER > /dev/null; then \
            groupmod -g 999 ${NEED_USER} \
            && usermod -u 999 -g 999 -s ${NEED_SHELL} ${NEED_USER}; \
        else \
            groupadd -g 999 ${NEED_USER} \
            && useradd -g 999 -u 999 -s ${NEED_SHELL} -md ${NEED_HOME} ${NEED_USER}; \
        fi \
        # Remove dummy user/group accounts
        && cat /etc/passwd | cut -d':' -f1 | sed "/^${USER_KEEP}\|${NEED_USER}$/d"  | xargs -n 1 userdel \
        && cat /etc/group  | cut -d':' -f1 | sed "/^${GROUP_KEEP}\|${NEED_USER}$/d" | xargs -n 1 groupdel; \
    else \
        # Remove dummy user/group accounts
        cat /etc/passwd | cut -d':' -f1 | sed "/^${USER_KEEP}$/d"  | xargs -n 1 userdel \
        && cat /etc/group  | cut -d':' -f1 | sed "/^${GROUP_KEEP}$/d" | xargs -n 1 groupdel; \
    fi


# App-specific config
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends rabbitmq-server erlang-base-hipe \
    && apt-clean --aggressive \
    && echo '[ { rabbit, [ { loopback_users, [ ] } ] } ].' > /etc/rabbitmq/rabbitmq.config \
    && chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq

USER rabbitmq

VOLUME /var/lib/rabbitmq
WORKDIR /var/lib/rabbitmq

COPY entrypoint /
ENTRYPOINT ["/tini", "--", "/entrypoint"]

EXPOSE 4369 5671 5672 15671 15672 25672 
CMD ["rabbitmq-server"]
