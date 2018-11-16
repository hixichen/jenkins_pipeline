#!/bin/bash
set -x


#
# RUN me where kubectl, VKE cli, envsubst is available
#

DEPLOYMENT=$1
IMAGE_VERION=$2

if [[ -z "$DEPLOYMENT"  ]]; then
    echo "forget to input deployment: unstable, stable, staging, prod?"
    echo "eg: ./deploy.sh [deployment] [image_version]"
    exit
fi

if [[ -z "$IMAGE_VERION"  ]]; then
    echo "forget to input image version?"
    echo "eg: ./deploy.sh [deployment] [image_version]"
    exit
fi

source ./env

# resource name
RESOURCE_NAME="$SERVICE_NAME-$DEPLOYMENT"

if [ "$DEPLOYMENT" = "unstable" ] || [ "$DEPLOYMENT" = "stable"  ]; then
  RESOURCE_NAME="$SERVICE_NAME-dev"
fi

echo  $RESOURCE_NAME


vke account login -t $ORG_ID  -r $API_TOKEN
vke cluster auth setup $RESOURCE_NAME -f $RESOURCE_NAME -p $RESOURCE_NAME

# ConfigMap
export CONFIG_MAP_NAME="$SERVICE_NAME-configmap-$DEPLOYMENT"

# Namespace
export NAMESPACE="$SERVICE_NAME-$DEPLOYMENT"

# Image version
export AUDIT_TRAIL_IMAGE_VERSION="$IMAGE_VERION"

# Image secret name
export IMAGE_SECRET_NAME=$IMAGE_SECRET_NAME

# AWS secret name
export AWS_SECRET_NAME=$AWS_SECRET_NAME


# replace the variables
envsubst < audit-trail.yaml.template > audit-trail.yaml

sleep 3

kubectl apply -f audit-trail.yaml

echo "done"