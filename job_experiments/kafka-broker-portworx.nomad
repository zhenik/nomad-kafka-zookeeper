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

  constraint {
    attribute = "${meta.storage}"
    value = "portworx"
  }

  # define group
  group "kafka-broker" {

    # define the number of times the tasks need to be executed
    count = 3

    restart {
      attempts = 3
      interval = "20m"
      delay    = "5m"
      mode     = "delay"
    }

    task "kafka" {
      driver = "docker"

      template {
        data = <<EOF
  KAFKA_CFG_ZOOKEEPER_CONNECT = "{{range service "kafka-zookeeper-client|any"}}{{.Address}}:{{.Port}},{{end}}"
  EOF

        destination = "secrets/file.env"
        env         = true
      }

      config {
        image = "bitnami/kafka:latest"
        labels {
            group = "kakfa-docker"
        }
        network_mode = "host"
        port_map {
            kafka = 9092
        }
        extra_hosts = ["${node.unique.name}:127.0.0.1"]
        volumes = [
          "name=kafka,size=1,repl=1/:/bitnami/kafka",
        ]
        volume_driver = "pxd"
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
        KAFKA_HEAP_OPTS="-Xmx250m -Xms250m"
        ALLOW_PLAINTEXT_LISTENER="yes"
      }
      service {
        port = "kafka"
        name = "kafka-broker"
        tags = ["kafka-broker"]
      }
    }
  }
}
