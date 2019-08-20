#!/bin/bash

set -e

ZOO_CONF_DIR=.
ZOO_DATA_DIR=.

# set myid based on ip match in generated $ZOO_CONF_DIR/zoo.cfg.dynamic
# myid=
# grep "10.102.45.113" job_experiments/zoo.cfg.dynamic | egrep -o '[0-9]=' | cut -c 1
myhost=`cat $ZOO_CONF_DIR/my_host`
grep "$myhost" $ZOO_CONF_DIR/zoo.cfg.dynamic | egrep -o '[0-9]=' | cut -c 1 > $ZOO_DATA_DIR/myid
