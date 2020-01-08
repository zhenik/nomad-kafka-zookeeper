job "service-discovery" {
  datacenters = [ "dc1"]
  type = "service"
  update {
    max_parallel = 1
  }

  group "some" {
    count = 3
    task "task" {
      driver = "docker"
      config {
        image = "hashicorp/http-echo"
        args = ["-text", "hello world"]
        port_map = {
          abcdef = "5678"
        }
      }
      service {
        tags = ["default"]
        port = "abcdef"
        check {
          type = "tcp"
          port = "abcdef"
          interval = "10s"
          timeout = "2s"
        }
      }
      resources {
        cpu = 100
        network {
          mbits = 10
          port "abcdef" {}
        }
      }
    }
  }
}