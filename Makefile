MAC_DOCKER := 192.168.0.190
LINUX_DOCKER := 172.17.0.1
HOST_DOCKER := ${LINUX_DOCKER}
NETWORK_INTERFACE_MAC := en0
NETWORK_INTERFACE_LINUX := docker0
NETWORK_INTERFACE := ${NETWORK_INTERFACE_LINUX}


.PHONY: all
all:
.PHONY: exports
exports:
	export NOMAD_ADDR=http://${HOST_DOCKER}:4646

.PHONY: consul
consul:
	sudo consul agent -dev -client=${HOST_DOCKER} -dns-port=53

.PHONY: nomad
nomad:
	sudo nomad agent -dev -bind=${HOST_DOCKER} -network-interface=${NETWORK_INTERFACE} -consul-address=${HOST_DOCKER}:8500

.PHONY: vault
vault:
	sudo vault server -dev --dev-listen-address=${HOST_DOCKER}:8200 -dev-root-token-id=root


.PHONY: zoo-run
zoo-run:
	nomad run ./job_experiments/zookeeper_unique_tasks.nomad

.PHONY: zoo-stop
zoo-stop:
	nomad stop kafka-zookeeper
