#!/bin/bash

# https://github.com/dprails/nomad-kafka-zookeeper/blob/master/docker/kafka-zookeeper/docker-entrypoint.sh
set -e

# sleep for 60s to allow nomad services to be registered
sleep 20

## create the zookeeper dynamic cfg from consul template
#if [[ -z "$CONSUL_HTTP_ADDR" ]]; then
#  consul-template -once -consul-addr=${CONSUL_HTTP_ADDR} -template /consul-templates/zookeeper-services.ctpl:$ZOO_CONF_DIR/zoo.cfg.dynamic
#else
#  consul-template -once -template /consul-templates/zookeeper-services.ctpl:$ZOO_CONF_DIR/zoo.cfg.dynamic
#fi

# decode the base64 truststore and keystore files
#base64 -d $ZOO_CONF_DIR/ssl/keystore_base64.p12 > /conf/ssl/keystore.p12
#base64 -d $ZOO_CONF_DIR/ssl/truststore_base64.jks > /conf/ssl/trustore.jks

# set myid based on ip match in generated $ZOO_CONF_DIR/zoo.cfg.dynamic
# myid=
# grep "10.102.45.113" job_experiments/zoo.cfg.dynamic | egrep -o '[0-9]=' | cut -c 1
#myhost=`cat $ZOO_CONF_DIR/my_host`
#grep "$myhost" $ZOO_CONF_DIR/zoo.cfg.dynamic | egrep -o '[0-9]=' | cut -c 1 > $ZOO_DATA_DIR/myid
#chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR" "$ZOO_CONF_DIR"

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR" "$ZOO_CONF_DIR"
    exec gosu zookeeper "$0" "$@"
fi

# source in SERVER_JVMFLAGS and CLIENT_JVMFLAGS
#. $ZOO_CONF_DIR/jvm_flags.sh

exec "$@"
