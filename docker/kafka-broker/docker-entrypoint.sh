#!/bin/bash

set -e

# decode the base64 truststore and keystore files
base64 -d $KAFKA_CONF_DIR/ssl/keystore_base64.p12 > /$KAFKA_CONF_DIR/ssl/keystore.p12
base64 -d $KAFKA_CONF_DIR/ssl/truststore_base64.jks > /$KAFKA_CONF_DIR/ssl/trustore.jks

# set brokerid
sed -i "s/broker.id=0/broker.id=$KAFKA_BROKER_ID/" $KAFKA_CONF_DIR/server.properties

# set advertised listeners
sed -i "s/#advertised.listeners=PLAINTEXT://your.host.name:9092/advertised.listeners=$KAFKA_ADVERTISED_LISTENERS" $KAFKA_CONF_DIR/server.properties

# set listeners protocol map
sed -i "s/#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL/$KAFKA_LISTENER_PROTOCOL_MAP" $KAFKA_CONF_DIR/server.properties

# set zookeeper connection string
sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$KAFKA_ZOOKEEPER_CONNECT/" $KAFKA_CONF_DIR/server.properties

# set kafka data directory
sed -i "s/log.dirs=/tmp/kafka-logs/logs.dirs=$KAFKA_DATA_DIR/" $KAFKA_CONF_DIR/server.properties

# update kafka-server-start.sh to pull in ZK_CLIENT_JVMFLAGS
sed -i 's/EXTRA_ARGS=${EXTRA_ARGS-'-name kafkaServer -loggc'}/EXTRA_ARGS="-name kafkaServer -loggc $ZK_CLIENT_JVMFLAGS/' $KAFKA_CONF_DIR/server.properties

# Allow the container to be started with `--user`
if [[ "$1" = 'kafka-server-start.sh' && "$(id -u)" = '0' ]]; then
    chown -R kafka "$KAFKA_CONF_DIR"
    exec gosu kafka "$0" "$@"
fi

# source in ZK_CLIENT_JVMFLAGS
. $KAFKA_CONF_DIR/jvm_flags.sh

exec "$@"
