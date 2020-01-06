MAVEN := './mvnw'
MAC_HOST :=192.168.0.190

.PHONY: all
all:

.PHONY: consul
consul:
	sudo consul agent -dev -client=192.168.0.190 -dns-port=53

.PHONY: nomad
nomad:
	sudo nomad agent -dev -bind=192.168.0.190 -network-interface=en0 -consul-address=192.168.0.190:8500

.PHONY: vault
vault:
	sudo vault server -dev --dev-listen-address=192.168.0.190:8200 -dev-root-token-id=root

