job "env-variables" {
  datacenters = [ "dc1"]
  type = "service"
  update {
    max_parallel = 1
  }

  group "some" {
    count = 3
    task "task" {
      driver = "docker"
      //ID
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
1
EOF
      }
      //default config
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      //dynamic config
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "restart"
        splay = "1m"
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
        network_mode = "host"
        port_map {
          client = 2181
          peer1 = 2888
          peer2 = 3888
          httpBind = 8080
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
          port "httpBind" {}
        }
      }
      service {
        port = "client"
        tags = [
          "tag-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "tag-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "tag-peer2"
        ]
      }
    }
  }
}