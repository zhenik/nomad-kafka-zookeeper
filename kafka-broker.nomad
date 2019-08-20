# Zookeeper

job "kafka-broker" {
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
  group "kafka-broker" {

    # define the number of times the tasks need to be executed
    count = 3

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "kafka" {
      driver = "docker"

      template {
        destination = "local/conf/brokerid"
        change_mode = "noop"
        data = <<EOF
{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
EOF
      }
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
kafka.root.logger=INFO, CONSOLE, ROLLINGFILE
kafka.console.threshold=INFO
kafka.log.dir=/kafka/log
kafka.log.file=kafka.log
kafka.log.threshold=INFO
kafka.tracelog.dir=/kafka/log
kakfa.tracelog.file=kafka_trace.log

# Kafka Logging Configuration
log4j.rootLogger=${kafka.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${kafka.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${kafka.log.threshold}
log4j.appender.ROLLINGFILE.File=${kafka.log.dir}/${kafka.log.file}

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
ZK_CLIENT_JVMFLAGS="-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty -Dzookeeper.client.secure=true"
ZK_CLIENT_JVMFLAGS="ZK_CLIENT_JVMFLAGS -Dzookeeper.ssl.keyStore.location=/conf/ssl/keystore.p12 -Dzookeeper.ssl.keyStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.keystore_password}}{{end}}"
export ZK_CLIENT_JVMFLAGS="ZK_CLIENT_JVMFLAGS -Dzookeeper.ssl.trustStore.location=/conf/ssl/truststore.jks -Dzookeeper.ssl.trustStore.password={{with secret "secret/teams/sre/kafka-poc/zookeeper/mtls"}}{{.Data.truststore_password}}{{end}}"
  EOF
      }
      template {
        data = <<EOF
  KAFKA_ZOOKEEPER_CONNECT = "{{range service "kafka-zookeeper-client|any"}}{{.Address}}:{{.Port}},{{end}}"
  EOF
        destination = "secrets/file.env"
        env         = true
      }

      config {
        image = "registry.simulpong.com/kafka-broker:latest"
        labels {
            group = "kakfa-docker"
        }
        network_mode = "host"
        port_map {
            kafka = 9092
        }
        volumes = [
          "local/data:/kafka"
        ]
        extra_hosts = [
            "${node.unique.name}:127.0.0.1"
        ]
      }
      resources {
        cpu = 100
        memory = 500
        network {
            mbits = 10
            port "kafka" {}
        }
      }
      env {
        KAFKA_BROKER_ID="{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}"
        KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://${NOMAD_IP_kafka}:9092"
        KAFKA_LISTENER_PROTOCOL_MAP="PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL"
        KAFKA_HEAP_OPTS="-Xmx250m -Xms250m"
        KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/conf/log4j.properties"
        KAFKA_DATA_DIR="/kafka"
      }
      service {
        port = "kafka"
        name = "kafka-broker"
        tags = ["kafka-broker"]
      }
    }
  }
}
