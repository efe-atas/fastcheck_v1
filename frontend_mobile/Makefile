FLUTTER ?= flutter

.PHONY: dev-machine-ip ios-dev-run

dev-machine-ip:
	$(FLUTTER) pub run tool/update_dev_machine_ip.dart --platform=ios

ios-dev-run: dev-machine-ip
	$(FLUTTER) run -d ios
