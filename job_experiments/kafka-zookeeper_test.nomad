# Zookeeper

job "kafka-zookeeper" {
  # Specify Region
//  region = "us-west"

  # Specify Datacenter
  datacenters = ["dc1"]

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
//      template {
//        destination = "local/conf/my_host"
//        change_mode = "noop"
//        data = <<EOF
//{{ $i | add 1 }}
//EOF
//      }
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=true
reconfigEnabled=true
skipACL=true
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
{{range $i, $clients := service "kafka-zookeeper-client|any"}}
server.{{ $i | add 1 }}={{.Address}}:{{with $peers1 := service "kafka-zookeeper-peer1|any"}}
{{with index $peers1 $i}}{{.Port}}{{end}}{{end}}:
{{with $peers2 := service "kafka-zookeeper-peer2|any"}}
{{with index $peers2 $i}}{{.Port}}{{end}}{{end}};{{.Port}}
{{ end }}
EOF
      }
      config {
        image = "zhenik/zookeeper-nomad:3.5.5"
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
