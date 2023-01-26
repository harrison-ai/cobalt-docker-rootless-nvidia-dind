#!/bin/sh
# Kubernetes Rootless NVIDIA DIND entrypoint script

set -eux

# Write GPUs to NVIDIA_VISIBLE_DEVICES in ConfigMap
if [ ! -z "${GPU_CONFIGMAP-}" ]; then
	python3 allocator.py
fi

# Link image cache path to a shared location
# USED WITH CAUTION!
if [ ! -z "${DOCKER_OVERLAY_PATH-}" ]; then
	# Make sure base path exists
	mkdir -p /home/rootless/.local/share/docker/image
	chown 1000 /home/rootless/.local/share/docker/image

	# Link in overlay

	rm -rf /home/rootless/.local/share/docker/overlay
	mkdir -p ${DOCKER_OVERLAY_PATH}/overlay
	chmod 777 ${DOCKER_OVERLAY_PATH}/overlay
	chown 1000 ${DOCKER_OVERLAY_PATH}/overlay
    ln -s ${DOCKER_OVERLAY_PATH}/overlay /home/rootless/.local/share/docker/overlay

	rm -rf /home/rootless/.local/share/docker/overlay2
	mkdir -p ${DOCKER_OVERLAY_PATH}/overlay2
	chmod 777 ${DOCKER_OVERLAY_PATH}/overlay2
	chown 1000 ${DOCKER_OVERLAY_PATH}/overlay2
    ln -s ${DOCKER_OVERLAY_PATH}/overlay2 /home/rootless/.local/share/docker/overlay2

	# Link in image overlay2
	rm -rf /home/rootless/.local/share/docker/image/overlay
	mkdir -p ${DOCKER_OVERLAY_PATH}/image/overlay
	chmod 777 ${DOCKER_OVERLAY_PATH}/image/overlay
	chown 1000 ${DOCKER_OVERLAY_PATH}/image/overlay
	ln -s ${DOCKER_OVERLAY_PATH}/image/overlay /home/rootless/.local/share/docker/image/overlay

	rm -rf /home/rootless/.local/share/docker/image/overlay2
	mkdir -p ${DOCKER_OVERLAY_PATH}/image/overlay2
	chmod 777 ${DOCKER_OVERLAY_PATH}/image/overlay2
	chown 1000 ${DOCKER_OVERLAY_PATH}/image/overlay2
	ln -s ${DOCKER_OVERLAY_PATH}/image/overlay2 /home/rootless/.local/share/docker/image/overlay2
fi 

# Will set the default program as dockerd with args
# and allows user to override completely.
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
	set -- dockerd \
		--host=tcp://0.0.0.0:2375 \
		--tls=false \
		"$@"
fi

# Only when we want to run dockerd (should be the case)
if [ "$1" = 'dockerd' ]; then
	# We expect to initially run as root so we can mount
	# sys paths then re-exec as rootless user
	if [ "$(id -u)" = '0' ]; then
		mkdir -p /unmasked-proc
		mount -t proc proc /unmasked-proc
		mkdir -p /unmasked-sys
		mount -t sysfs sysfs /unmasked-sys
		mkdir -p /dev/net
		mknod /dev/net/tun c 10 200 || :
		chmod 666 /dev/net/tun
		exec setpriv --reuid=rootless --regid=rootless \
			--init-groups --reset-env "$0" "$@"
	fi

	# Remove any lagging docker pids
	find /run /var/run -iname 'docker*.pid' -delete || :

	# Set environment
	uid="$(id -u)"
	: "${XDG_RUNTIME_DIR:=/run/user/$uid}"
	PATH=/usr/local/sbin:/usr/sbin:/sbin:${PATH}
	export XDG_RUNTIME_DIR PATH

	# Use dumb-init to properly handle signals
	# Use rootlesskit to kick off dockerd rootless
	exec dumb-init rootlesskit \
		--pidns \
		--disable-host-loopback \
		--net=slirp4netns \
		--port-driver=builtin \
		--publish 0.0.0.0:2375:2375/tcp \
		--copy-up=/etc \
		--copy-up=/run \
		"$@"
fi

export DOCKER_HOST='tcp://127.0.0.1:2375'
exec "$@"
