
IMAGE=ghcr.io/inti-cmnb/kicad7_auto:1.6.3-2_k7.0.9_d12.1

.PHONY: run-kibot
run-kibot:
	podman run -v "$(PWD):/build" -w /build/hw $(IMAGE) kibot -v -b tp1.kicad_pcb -c config.kibot.yaml

