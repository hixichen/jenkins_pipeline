#!/bin/bash -xe


ORG_ID=$1
API_TOKEN=$2
SERVICE_NAME=$3
DEPLOYMENT=$4

if [ -z "$ORG_ID"  ] || [ -z "$API_TOKEN" ]; then
    echo "forget to input org id or api token?"
    exit -1
fi



if [ -z "$SERVICE_NAME"  ] || [ -z "$DEPLOYMENT" ]; then
    echo "forget to input service name?"
    echo "forget to input deployment: unstable, stable, staging, prod?"
    exit -1
fi

# resource name
RESOURCE_NAME="$SERVICE_NAME-$DEPLOYMENT"

if [ "$DEPLOYMENT" = "unstable" ] || [ "$DEPLOYMENT" = "stable" ]; then
  RESOURCE_NAME="$SERVICE_NAME-dev"
fi


# Namespace
NAMESPACE="$SERVICE_NAME-$DEPLOYMENT"

if [ -z "$ORG_ID"  ] || [ -z "$API_TOKEN" ]; then
    echo "Need org id and api token to login into VKE "
    exit -1
fi

export CASCADE_CONFIG="./"
./vke account login -t $ORG_ID  -r $API_TOKEN
./vke cluster auth setup $RESOURCE_NAME -f $RESOURCE_NAME -p $RESOURCE_NAME