# Copyright (C) 2024 - Tillitis AB
# SPDX-License-Identifier: MIT
#
KIBOT_IMAGE=ghcr.io/inti-cmnb/kicad7_auto:1.6.3-2_k7.0.9_d12.1

TKEY_BUILDER_IMAGE=ghcr.io/tillitis/tkey-builder:4

.PHONY: run-kibot
run-kibot:
	podman run --rm -v "$(PWD):/build" -w /build/hw $(KIBOT_IMAGE) kibot -v -b tp1.kicad_pcb -c config.kibot.yaml

.PHONY: fw
fw-podman:
	podman run --rm --mount type=bind,source="$(PWD)/fw",target=/build -w /build -it \
	$(TKEY_BUILDER_IMAGE) ./build.sh

.PHONY: fw
fw:
	cd fw && ./build.sh

.PHONY: clean
clean:
	rm -rf fw/build
	rm -rf hw/output
