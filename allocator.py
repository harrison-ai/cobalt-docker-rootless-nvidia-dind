#!/usr/bin/env python3
#
# Share NVIDIA_VISIBLE_DEVICES to ConfigMap

from kubernetes import client, config
from kubernetes.client.rest import ApiException
import os

# Read k8s config from environment KUBERNETES environment variables
config.load_incluster_config()

api_instance = client.CoreV1Api()
name = os.environ["GPU_CONFIGMAP"]
namespace = open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read()
body = client.V1ConfigMap(
    api_version="v1",
    kind="ConfigMap",
    data=dict(NVIDIA_VISIBLE_DEVICES=os.environ["NVIDIA_VISIBLE_DEVICES"]),
    metadata=dict(name=name),
)

try:
    api_response = api_instance.replace_namespaced_config_map(
        name, namespace, body, pretty="true"
    )
    print(api_response)
except ApiException as e:
    print("Exception when calling CoreV1Api->replace_namespaced_config_map: %s\n" % e)
    exit(1)
