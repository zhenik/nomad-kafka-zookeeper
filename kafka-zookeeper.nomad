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
    max_parallel = 3
  }

  # define group
  group "zk" {

    # define the number of times the tasks need to be executed
    count = 3

    restart {
      attempts = 20
      interval = "20m"
      delay    = "5s"
      mode     = "delay"
    }

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "zookeeper" {
      driver = "docker"

      vault {
        policies = ["secret_sre"]
        change_mode = "noop"
      }

      template {
        destination = "local/conf/my_host"
        change_mode = "noop"
        data = <<EOF
{{ env "NOMAD_IP_client" }}
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
4lw.commands.whitelist=*
secureClientPort=2281
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
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
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      template {
        destination = "local/conf/ssl/keystore_base64.p12"
        change_mode = "noop"
        data =<<EOF
{{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.keystore}}{{end}}
EOF
      }
      template {
        destination = "local/conf/ssl/truststore_base64.jks"
        change_mode = "noop"
        data =<<EOF
{{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.truststore}}{{end}}
EOF
      }
      template {
        destination = "local/conf/jvm_flags.sh"
        data = <<EOF
#!/usr/bin/env bash
SERVER_JVMFLAGS="-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory"
SERVER_JVMFLAGS="$SERVER_JVMFLAGS -Dzookeeper.ssl.keyStore.location=/conf/ssl/keystore.p12 -Dzookeeper.ssl.keyStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.keystore_password}}{{end}}"
export SERVER_JVMFLAGS="$SERVER_JVMFLAGS -Dzookeeper.ssl.trustStore.location=/conf/ssl/truststore.jks -Dzookeeper.ssl.trustStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.truststore_password}}{{end}}"
CLIENT_JVMFLAGS="-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty -Dzookeeper.client.secure=true"
CLIENT_JVMFLAGS="$CLIENT_JVMFLAGS -Dzookeeper.ssl.keyStore.location=/conf/ssl/keystore.p12 -Dzookeeper.ssl.keyStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.keystore_password}}{{end}}"
export CLIENT_JVMFLAGS="$CLIENT_JVMFLAGS -Dzookeeper.ssl.trustStore.location=/conf/ssl/truststore.jks -Dzookeeper.ssl.trustStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.truststore_password}}{{end}}"
  EOF
      }
      config {
        image = "registry.simulpong.com/kafka-zookeeper:latest"
        labels {
            group = "zk-docker"
        }
        network_mode = "host"
        port_map {
            client = 2281
            secure_client = 2281
            peer1 = 2888
            peer2 = 3888
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
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
          port "secure_client" {}
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
        check {
          type = "script"
          name = "zookeeper_cfg_exists"
          command = "/bin/bash"
          args = ["-c", "test -f /conf/zoo.cfg"]
          interval = "5s"
          timeout = "5s"
          initial_status = "passing"
        }
      }
      service {
        port = "peer1"
        name = "kafka-zookeeper-peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
        check {
          type = "script"
          name = "zookeeper_cfg_exists"
          command = "/bin/bash"
          args = ["-c", "test -f /conf/zoo.cfg"]
          interval = "5s"
          timeout = "5s"
          initial_status = "passing"
        }
      }
      service {
        port = "peer2"
        name = "kafka-zookeeper-peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
        check {
          type = "script"
          name = "zookeeper_cfg_exists"
          command = "/bin/bash"
          args = ["-c", "test -f /conf/zoo.cfg"]
          interval = "5s"
          timeout = "5s"
          initial_status = "passing"
        }
      }
    }
  }
}
