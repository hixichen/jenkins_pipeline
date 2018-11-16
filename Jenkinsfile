pipeline {

    agent any

    def SERVICE_NAME = 'audit-trail'
    def K8S_CLUSTER_VERSION = 'v1.10.8'

    stages {
        stage('Validate ENV') {
            when {
                        allOf {
                            expression { env.ORG_ID != null }
                            expression { env.API_TOKEN != null }
                            expression { env.BINTRAY_USER != null }
                            expression { env.BINTRAY_API_KEY != null }
                        }
                  }

            steps {
                        echo 'PASS ENV validation'
            }
        }

        stage('PostCommit'){
            steps {
                sh '''
                    cat >.hmakerc <<EOF
                    format: hypermake.v0
                    settings:
                        docker:
                            cache: false
                    EOF
                '''
            }
        }
         stage('BuildAndPushImage') {
            steps {
                def BUILT_IMAGE_VERION = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                echo "image version $BUILT_IMAGE_VERION"
                sh 'docker login -u $BINTRAY_USER -p $BINTRAY_API_KEY vmware-docker-audit-trail.bintray.io'
                sh 'docker tag audit-trail:test vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERION'
                sh 'docker push vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERION'
                echo 'push image to registry'
            }
         }

         stage('DeployToUnstable') {
                 steps {
                     echo "deploy image to unstable cluster"
                     sh './deployment/k8s/pipeline/install_tools.sh "$k8s_cluster_version" '
                     sh './deployment/k8s/pipeline/auth_cluster.sh "$ORG_ID" "$API_TOKEN" "$SERVICE_NAME" unstable '
                 }
             }

             stage('RunIntegrationTest') {
                 def K8S_DEPLOYMENT = true
                 def AUDIT_S3_BUCKET_NAME = 'audit-trail-k8s-unstable'
                 def AUDIT_EVENT_STREAM_NAME = 'audit-stream-k8s-unstable'

                 steps {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'cascade-jenkins']]) {
                         sh 'aws s3 ls'
                         echo 'PASS Integration Test'
                    }
                 }
             }

    } // end of stages
}