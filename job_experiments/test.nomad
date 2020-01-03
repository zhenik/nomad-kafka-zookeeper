job "zk" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "zk" {
    count = 1

    task "zk" {
      driver = "docker"

      template {
        data = <<EOH
# test variable lookup
{{ $node_ip := env "NOMAD_IP_zk_port" }}ZOO_SIMPLE_VAR="{{ $node_ip }}"
# test range assignment
{{ range $i, $letters := "a" | split " " }}ZOO_SIMPLE_RANGE="{{ $letters }}"{{end}}
# test range over other services
{{ range $i, $services := service "redis-cache" }}ZOO_OTHER_SERVICE="{{ $services.Address }}"{{end}}
# test range over self services
{{range $i, $services := service "zk"}}ZOO_SELF_SERVICE="{{ $services.Address }}"{{end}}
EOH

        destination = "local/zkid.env"
        change_mode = "noop"
        env         = true
      }

      config {
        image        = "alpine:latest"
        command = "/bin/sh"
        args = ["-c", "echo '>>>>>>>>>>>>>>> FROM ENV_VARS'; printenv | grep ZOO_; echo; echo '>>>>>>>>>>>>>>> FROM ENV_FILE'; cat /local/zkid.env; sleep 40000"]
      }
//      >>>>>>>>>>>>>>> FROM ENV_VARS
//  ZOO_SIMPLE_RANGE=a
//  ZOO_SIMPLE_VAR=172.17.0.1
//
//  >>>>>>>>>>>>>>> FROM ENV_FILE
//# test variable lookup
//ZOO_SIMPLE_VAR="172.17.0.1"
//# test range assignment
//ZOO_SIMPLE_RANGE="a"
//# test range over other services
//
//# test range over self services
      service {
        name         = "zk"
        port         = "zk_port"
        address_mode = "host"
      }

      resources {
        cpu    = 1024 # 1024 Mhz
        memory = 512  # 512MB

        network {
          port "zk_port" {}
        }
      }
    }
  }
}