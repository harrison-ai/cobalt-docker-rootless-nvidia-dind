#!/usr/bin/env python3
#
# Share NVIDIA_VISIBLE_DEVICES to ConfigMap

from kubernetes import client, config
from kubernetes.client.rest import ApiException
import os
import glob

# Read k8s config from environment KUBERNETES environment variables
config.load_incluster_config()

api_instance = client.CoreV1Api()
name = os.environ["GPU_CONFIGMAP"]
namespace = open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read()

# Check for volume mounted GPUS first. Revert to environment variable.
# Allow os.environ to throw if empty.
visible_devices=','.join([os.path.basename(x) for x in glob.glob('/var/run/nvidia-container-devices/*GPU*')])
if not visible_devices:
    visible_devices=os.environ["NVIDIA_VISIBLE_DEVICES"]

body = client.V1ConfigMap(
    api_version="v1",
    kind="ConfigMap",
    data=dict(NVIDIA_VISIBLE_DEVICES=visible_devices),
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
