JOB_NAME=kafka-zookeeper
ARG="/apache-zookeeper-3.5.5-bin/bin/zkServer.sh status"

nomad alloc exec -job -task=zk1 $JOB_NAME /bin/bash -c "$ARG" && \
    nomad alloc exec -job -task=zk2 $JOB_NAME /bin/bash -c "$ARG" && \
    nomad alloc exec -job -task=zk3 $JOB_NAME /bin/bash -c "$ARG"