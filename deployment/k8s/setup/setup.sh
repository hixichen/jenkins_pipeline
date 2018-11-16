#!/bin/bash

set -x

DEPLOYMENT=$1
REGION=$2

if [[ -z "$DEPLOYMENT"  ]]; then
    echo "forget to input deployment: unstable, stable, staging, prod?"
    echo "eg: ./setup.sh [deployment] [region]"
    exit
fi


# default region: us-west-2
if [[ -z "$REGION"  ]]; then
    REGION="us-west-2"
fi


source ./env


# resource name
RESOURCE_NAME="$SERVICE_NAME-$DEPLOYMENT"

if [ "$DEPLOYMENT" = "unstable" ] || [ "$DEPLOYMENT" = "stable" ]; then
  RESOURCE_NAME="$SERVICE_NAME-dev"
fi

echo $RESOURCE_NAME

# ConfigMap
CONFIG_MAP_NAME="$SERVICE_NAME-configmap-$DEPLOYMENT"

# Namespace
NAMESPACE="$SERVICE_NAME-$DEPLOYMENT"

vke account login -t $ORG_ID  -r $API_TOKEN
vke folder create $RESOURCE_NAME
vke folder set $RESOURCE_NAME
vke project create $RESOURCE_NAME
vke project set $RESOURCE_NAME

echo "cluster name: $RESOURCE_NAME, region: $REGION"
vke cluster create -n $RESOURCE_NAME -r $REGION
vke cluster auth setup $RESOURCE_NAME -f $RESOURCE_NAME -p $RESOURCE_NAME


sleep 1


kubectl create ns "$NAMESPACE"

kubectl create secret docker-registry "$IMAGE_SECRET_NAME" \
 --docker-server="https://vmware-docker-audit-trail.bintray.io" \
 --docker-username="$BINTRAY_USER_NAME" \
 --docker-password="$BINTRAY_API_TOKEN" \
 --docker-email="$BINTRAY_EMAIL" \
 -n "$NAMESPACE"

sleep 1

kubectl create secret generic "$AWS_SECRET_NAME" \
--from-literal=aws-access-id="$AWS_ACCESS_KEY_ID" \
--from-literal=aws-secret-access-key="$AWS_SECRET_ACCESS_KEY" \
-n "$NAMESPACE"


CONFIG_MAP_FILE="configmap-$DEPLOYMENT"

kubectl create configmap "$CONFIG_MAP_NAME" --from-env-file $CONFIG_MAP_FILE -n "$NAMESPACE"

echo "done"