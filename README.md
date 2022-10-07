# cobalt-rootless-nvidia-dind

Rootless dind (Docker in Docker) with NVIDIA container toolkit docker image. Runs a rootless docker daemon with TLS disabled and the NVIDIA container runtime available.

## 📖 Requirements

- Docker host requires Linux Kernel 5.11 to use overlayfs in user namespaces.
- Docker host needs NVIDIA container runtime to passthrough GPU.
- Container must be run with SYS_ADMIN capability.
- For Debian based Kubernetes hosts the annotation `"container.apparmor.security.beta.kubernetes.io/<dind-container>": "unconfined"` must exist for the pod.

## 💡 Motivation

To provide a container image that:

- Provides a rootless docker daemon service.
- Does not require privileged mode and minimum Linux Capabilities.
- Has NVIDIA container runtime baked in.

## 🔧 What's inside ?

The image is based on the `debian:bullseye-slim` and incorperates these major components:

* [rootlesskit](https://github.com/rootless-containers/rootlesskit)
* [nvidia-container-runtime](https://github.com/NVIDIA/nvidia-container-runtime)
* [docker engine](https://github.com/docker/engine)

## 🚀 Usage

Launching from the CLI:

```bash
docker run --rm -it --cap-add "SYS_ADMIN" cobalt-rootless-nvidia-dind:latest
```

As a Kubernetes deployment:

```apiVersion: apps/v1
kind: Deployment
metadata:
  name: dind
spec:
  selector:
    matchLabels:
      app: dind
  template:
    metadata:
      annotations:
        container.apparmor.security.beta.kubernetes.io/dind: unconfined
      labels:
        app: dind
    spec:
      containers:
        - name: docker
          image: cobalt-rootless-nvidia-dind:latest
          imagePullPolicy: Always
          resources:
            requests:
              cpu: 8
              memory: 32Gi
              nvidia.com/gpu: 2
            limits:
              cpu: 8
              memory: 32Gi
              nvidia.com/gpu: 2
          securityContext:
            capabilities:
              add:
                - SYS_ADMIN
          volumeMounts:
            - mountPath: /home/rootless/.local
              name: docker
      volumes:
        - name: docker
          emptyDir: {}
```

## 🙏 Thanks and credits

- [zhsj](https://github.com/zhsj): for their work on rootless dind.
- [ehfd](https://github.com/ehfd): for demonstrating bundling nvidia runtime components for dind use. 

## 🔑 License
This project is licensed under [Apache License 2.0](https://raw.githubusercontent.com/harrison-ai/harrison-ai-terraform-docker/master/LICENSE)


