#!/bin/bash -xe

SERVICE_NAME=$1
DEPLOYMENT=$2
IMAGE_VERION=$3

if [ -z "$SERVICE_NAME"  ] || [ -z "$DEPLOYMENT" ] || [ -z "$IMAGE_VERION" ]; then
    echo "forget to input service name?"
    echo "forget to input deployment: unstable, stable, staging, prod?"
    echo "forget to input image version?"
    exit -1
fi

# Namespace
NAMESPACE="$SERVICE_NAME-$DEPLOYMENT"

./kubectl set image deployment.v1.apps/$SERVICE_NAME \
    audit-trail="vmware-docker-audit-trail.bintray.io/audit-trail:$IMAGE_VERION" --record \
    -n $NAMESPACE

sleep 10

imageUpdateResult=$(time 60 ./kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE)
echo $imageUpdateResult | grep "successfully" > /dev/null
TESTRESULT=$?
if [ ${TESTRESULT} -ne 0 ];then
 exit -1
fi

podStatus=$(./kubectl get pods -n $NAMESPACE  -o=jsonpath='{.items[0].status.phase}' )
echo $podStatus | grep "Running" > /dev/null
TESTRESULT=$?
if [ ${TESTRESULT} -ne 0 ];then
 exit -1
fi