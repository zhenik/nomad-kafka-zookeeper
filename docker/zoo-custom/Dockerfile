FROM openjdk:8-jre-slim

ARG GPG_KEY=3F7A1D16FA4217B1DC75E1C9FFE35B7F15DFA1BA
ARG SHORT_DISTRO_NAME=zookeeper-3.5.5
ARG DISTRO_NAME=apache-zookeeper-3.5.5-bin
#ARG CONSUL_VERSION=1.5.3
#ARG CONSUL_TEMPLATE_VERSION=0.20.1

ENV ZOO_CONF_DIR=/conf \
    ZOO_DATA_DIR=/data \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_LOG_DIR=/logs \
    BIN_DIR=/bin

#ENV ZOO_CONF_DIR=/conf \
#    ZOO_DATA_DIR=/data \
#    ZOO_DATA_LOG_DIR=/datalog \
#    ZOO_LOG_DIR=/logs \
#    ZOO_TICK_TIME=2000 \
#    ZOO_INIT_LIMIT=5 \
#    ZOO_SYNC_LIMIT=2 \
#    ZOO_AUTOPURGE_PURGEINTERVAL=0 \
#    ZOO_AUTOPURGE_SNAPRETAINCOUNT=3 \
#    ZOO_MAX_CLIENT_CNXNS=60 \
#    ZOO_STANDALONE_ENABLED=true \
#    ZOO_ADMINSERVER_ENABLED=true \
#    BIN_DIR=/bin

# Add a user with an explicit UID/GID and create necessary directories
RUN set -eux
RUN groupadd -r zookeeper --gid=1000
RUN useradd -r -g zookeeper --uid=1000 zookeeper
RUN mkdir -p "$BIN_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"
RUN chown -R zookeeper:zookeeper "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"

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
        unzip; \
    rm -rf /var/lib/apt/lists/*; \
# Verify that gosu binary works
    gosu nobody true

# Download Apache Zookeeper, verify its PGP signature, untar and clean up
RUN set -eux;
RUN echo "https://www.apache.org/dist/zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz"
ADD "https://www.apache.org/dist/zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz" "./$DISTRO_NAME.tar.gz"
RUN export GNUPGHOME="$(mktemp -d)"
RUN tar -zxf "$DISTRO_NAME.tar.gz"
RUN mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR"
RUN rm -rf "$DISTRO_NAME.tar.gz"
RUN chown -R zookeeper:zookeeper "/$DISTRO_NAME"

EXPOSE 2181 2281 2888 3888 8080

ENV PATH=$PATH:$BIN_DIR:/$DISTRO_NAME/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

COPY docker-entrypoint.sh /
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
