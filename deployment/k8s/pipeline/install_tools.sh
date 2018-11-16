#!/bin/bash -xe

K8S_CLUSTER_VERSION=$1
if [ -z "$K8S_CLUSTER_VERSION"  ]; then
    echo "forget to input cluster version?"
    exit -1
fi

wget -N https://storage.googleapis.com:443/kubernetes-release/release/$K8S_CLUSTER_VERSION/bin/linux/amd64/kubectl -O ./kubectl
chmod +x kubectl 
wget -N https://s3.amazonaws.com/vke-cli-us-east-1/latest/linux64/vke -O ./vke
chmod +x vke