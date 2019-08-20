# Zookeeper

job "kafka-zookeeper" {
  # Specify Region
  region = "us-west"

  # Specify Datacenter
  datacenters = [ "alpha"]

  # Specify job type
  type = "service"

  # Run tasks in serial or parallel (1 for serial)
  update {
    max_parallel = 1
  }

  # define group
  group "zk" {

    # define the number of times the tasks need to be executed
    count = 3

    restart {
      attempts = 2
      interval = "5m"
      delay    = "30s"
      mode     = "delay"
    }

    task "zookeeper" {
      driver = "docker"
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
EOF
      }
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=true
dataDir=/data
server.{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1}}:{{ env "NOMAD_IP_client" }}:{{ env "NOMAD_PORT_peer1" }}:{{ env "NOMAD_PORT_peer2" }};{{ env "NOMAD_PORT_client" }}
EOF
      }
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE
zookeeper.console.threshold=INFO
zookeeper.log.dir=/zookeeper/log
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.file=zookeeper_trace.log

# ZooKeeper Logging Configuration
log4j.rootLogger=${zookeeper.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%nEOF
      }
      config {
        image = "zookeeper:3.5.5"
        labels {
            group = "zk-docker"
        }
        network_mode = "host"
        port_map {
            client = 2181
            peer1 = 2888
            peer2 = 3888
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data"
        ]
      }
      env {
        ZOO_LOG4J_PROP="INFO,CONSOLE"
      }
      resources {
        cpu = 100
        memory = 128
        network {
          mbits = 10
          port "client" {}
          port "peer1" {}
          port "peer2" {}
        }
      }
      service {
        port = "client"
        name = "kafka-zookeeper-client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        name = "kafka-zookeeper-peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        name = "kafka-zookeeper-peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }
  }
}
