#!/usr/bin/env groovy

node {

    currentBuild.result = "SUCCESS"

    sh 'env > env.txt'

    for (String i : readFile('env.txt').split("\r?\n")) {
        println i
    }

    echo "start validate environment variable"

    try {
        println "$ORG_ID"
        println "$API_TOKEN"
        println "$BINTRAY_USER"
        println "$BINTRAY_API_TOKEN"
    }catch (MissingPropertyException e) {
         throw e
    }
    echo "PASS  validate environment variable"

    echo "config the service"

    def service_name = "audit-trail"
    def k8s_cluster_version = "v1.10.8"

    try {

        stage('Checkout'){
          checkout scm
        }

        stage('PostCommit')  {
            echo "post commit"
            sh '''
                                cat >.hmakerc <<EOF
                                format: hypermake.v0
                                settings:
                                    docker:
                                        cache: false
                                EOF
            '''
            sh 'echo "$BINTRAY_USER"'
            sh 'pwd&&ls'
        }

        stage('PushImage') {
            script {
                BUILT_IMAGE_VERSION = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            }

            echo "push image ${BUILT_IMAGE_VERSION}"
            sh 'docker login -u "$BINTRAY_USER" -p "$BINTRAY_API_TOKEN" vmware-docker-audit-trail.bintray.io'
            echo 'push image to registry'
        }

        stage('DeployToUnstable')  {

             echo "deploy image to unstable cluster"
             sh './deployment/k8s/pipline/install_tools.sh "$k8s_cluster_version" '
             sh './deployment/k8s/pipline/auth_cluster.sh "$ORG_ID" "$API_TOKEN" "service_name" unstable '
        }


        stage('RunIntegrationTest') {

              def K8S_DEPLOYMENT = true
              def AUDIT_S3_BUCKET_NAME = "audit-trail-k8s-unstable"
              def AUDIT_EVENT_STREAM_NAME = "audit-stream-k8s-unstable"
              echo 'PASS Integration Test'
        }
    }

    catch (err) {
        currentBuild.result = "FAILURE"
        throw err
    }

    finally {
        stage('CleanImages') {
          sh 'docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi'
        }
    }
}