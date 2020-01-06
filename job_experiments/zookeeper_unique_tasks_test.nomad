job "kafka-zookeeper" {
  datacenters = [ "dc1"]
  type = "service"
  update { max_parallel = 1 }
  group "zk" {
    count = 1
    restart {
      attempts = 2
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "zk1" {
      driver = "docker"
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        splay = "30s"
        data = <<EOF
server.1={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
server.2={{ env "NOMAD_IP_zk2_client" }}:{{ env "NOMAD_PORT_zk2_peer1" }}:{{ env "NOMAD_PORT_zk2_peer2" }};{{ env "NOMAD_PORT_zk2_client" }}
server.3={{ env "NOMAD_IP_zk3_client" }}:{{ env "NOMAD_PORT_zk3_peer1" }}:{{ env "NOMAD_PORT_zk3_peer2" }};{{ env "NOMAD_PORT_zk3_client" }}
EOF
      }
      config {
        image = "alpine:latest"
        command = "/bin/sh"
        args = ["-c", "ls local/conf/; cat local/conf/zoo.cfg; cat local/conf/zoo.cfg.dynamic; env; sleep 40000"]
        labels { group = "zk-docker" }
        network_mode = "host"
        port_map {
            client = 2181
            peer1 = 2888
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
          port "peer1" {}
          port "peer2" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }

    task "zk2" {
      driver = "docker"
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "noop"
        data = <<EOF
server.1={{ env "NOMAD_IP_zk1_client" }}:{{ env "NOMAD_PORT_zk1_peer1" }}:{{ env "NOMAD_PORT_zk1_peer2" }};{{ env "NOMAD_PORT_zk1_client" }}
server.2={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
server.3={{ env "NOMAD_IP_zk3_client" }}:{{ env "NOMAD_PORT_zk3_peer1" }}:{{ env "NOMAD_PORT_zk3_peer2" }};{{ env "NOMAD_PORT_zk3_client" }}
EOF
      }
      config {
        image = "alpine:latest"
        command = "/bin/sh"
        args = ["-c", "ls local/conf/; cat local/conf/zoo.cfg; cat local/conf/zoo.cfg.dynamic; env; sleep 40000"]
        labels {
          group = "zk-docker"
        }
        network_mode = "host"
        port_map {
            client = 2181
            peer1 = 2888
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
          port "peer1" {}
          port "peer2" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }
    task "zk3" {
      driver = "docker"
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "noop"
        data = <<EOF
server.1={{ env "NOMAD_IP_zk1_client" }}:{{ env "NOMAD_PORT_zk1_peer1" }}:{{ env "NOMAD_PORT_zk1_peer2" }};{{ env "NOMAD_PORT_zk1_client" }}
server.2={{ env "NOMAD_IP_zk2_client" }}:{{ env "NOMAD_PORT_zk2_peer1" }}:{{ env "NOMAD_PORT_zk2_peer2" }};{{ env "NOMAD_PORT_zk2_client" }}
server.3={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
EOF
      }
      config {
        image = "alpine:latest"
        command = "/bin/sh"
        args = ["-c", "ls local/conf/; cat local/conf/zoo.cfg; cat local/conf/zoo.cfg.dynamic; env; sleep 40000"]
        labels {
          group = "zk-docker"
        }
        network_mode = "host"
        port_map {
          client = 2181
          peer1 = 2888
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
          port "peer1" {}
          port "peer2" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }
  }
}
