# kafka-poc


## verify zookeeper cluster is up
run the following against each node to verify it is either a leader or follower, pull ip ports from kafka-zookeper-client service in consul
```
$ echo stat | nc  <kafka-zookeeper-client-1 ip> <kafka-zookeeper-client-1 port> | grep Mode
Mode: follower
$ echo stat | nc  <kafka-zookeeper-client-2 ip> <kafka-zookeeper-client-2 port> | grep Mode
Mode: follower
$ echo stat | nc  <kafka-zookeeper-client-2 ip> <kafka-zookeeper-client-2 port> | grep Mode
Mode: leader
```

## verify kafka cluster
for all these commands pull kafka-zookeeper-client-1 ip and port from consul

### download kafka zookeeper tools onto OS X
```
$ brew install kafka
```

### verify number of brokers
```
zookeeper-shell <zookeeper-client ip>:<zookeeper client port> ls /brokers/ids
Connecting to 10.102.44.92:22475

WATCHER::

WatchedEvent state:SyncConnected type:None path:null
[1005, 1004, 1003] # => id of each broker
```

### add topic
```
$ kafka-topics --zookeeper <kafka-zookeeper-client-1 ip>:<kafka-zookeeper-client-1 port> --create  --replication-factor 2 --partitions 3 --topic <topic name>
```

### list topics
```
$ kafka-topics --zookeeper <kafka-zookeeper-client-1 ip>:<kafka-zookeeper-client-1 port> --list
```

### Validate
docker exec <conainer_id> /apache-zookeeper-3.5.5-bin/bin/zkServer.sh status

docker exec 80ca /apache-zookeeper-3.5.5-bin/bin/zkServer.sh status &&
    docker exec 699a /apache-zookeeper-3.5.5-bin/bin/zkServer.sh status && 
    docker exec e035 /apache-zookeeper-3.5.5-bin/bin/zkServer.sh status