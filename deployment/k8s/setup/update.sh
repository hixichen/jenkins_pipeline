#!/bin/bash
set -x


#
# RUN me where kubectl, VKE cli is available
#

DEPLOYMENT=$1
IMAGE_VERION=$2

if [[ -z "$DEPLOYMENT"  ]]; then
    echo "forget to input deployment: unstable, stable, staging, prod?"
    echo "eg: ./update.sh [deployment] [image_version]"
    exit
fi

if [[ -z "$IMAGE_VERION"  ]]; then
    echo "forget to input image version?"
    echo "eg: ./update.sh [deployment] [image_version]"
    exit
fi

source ./env

# resource name
RESOURCE_NAME="$SERVICE_NAME-$DEPLOYMENT"

if [ "$DEPLOYMENT" = "unstable" ] || [ "$DEPLOYMENT" = "stable" ]; then
  RESOURCE_NAME="$SERVICE_NAME-dev"
fi


# Namespace
NAMESPACE="$SERVICE_NAME-$DEPLOYMENT"


vke account login -t $ORG_ID  -r $API_TOKEN
vke cluster auth setup $RESOURCE_NAME -f $RESOURCE_NAME -p $RESOURCE_NAME

kubectl set image deployment.v1.apps/audit-trail \
    audit-trail="vmware-docker-audit-trail.bintray.io/audit-trail:$IMAGE_VERION" --record \
    -n "$NAMESPACE"

echo "done"