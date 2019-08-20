FROM openjdk:8-jre-slim

ARG GPG_KEY=3F7A1D16FA4217B1DC75E1C9FFE35B7F15DFA1BA
ARG SHORT_DISTRO_NAME=2.3.0
ARG DISTRO_NAME=kafka_2.12-2.3.0

ENV KAFKA_CONF_DIR=/conf

# Add a user with an explicit UID/GID and create necessary directories
RUN set -eux && \
    groupadd -r kafka --gid=1000 && \
    useradd -r -g kafka --uid=1000 kafka && \
    mkdir -p "$KAFKA_CONF_DIR" && \
    chown kafka:kafka "$KAFKA_CONF_DIR"

# Install required packages
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        dirmngr \
        gosu \
        gnupg \
        netcat \
        wget \
        unzip && \
    rm -rf /var/lib/apt/lists/* && \
# Verify that gosu binary works
    gosu nobody true

# Download Apache Kafka, verify its PGP signature, untar and clean up
RUN set -eux; \
    wget -q "https://www-us.apache.org/dist/kafka/$SHORT_DISTRO_NAME/$DISTRO_NAME.tgz" && \
    wget -q "https://www.apache.org/dist/kafka/$SHORT_DISTRO_NAME/$DISTRO_NAME.tgz.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$GPG_KEY" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$DISTRO_NAME.tgz.asc" "$DISTRO_NAME.tgz" && \
    tar -zxf "$DISTRO_NAME.tar.gz" && \
    mv "$DISTRO_NAME/config/server.properties" "$KAFKA_CONF_DIR/" && \
    mv "$DISTOR_NAME/config/log4j.properties" "$KAFKA_CONF_DIR/" && \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tgz" "$DISTRO_NAME.tgz.asc" && \
    chown -R kafka:kafka "/$DISTRO_NAME"

WORKDIR $DISTRO_NAME

ENV PATH=$PATH:/$DISTRO_NAME/bin

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kafka-server-start.sh", "$KAFKA_CONF_DIR/server.properties"]
