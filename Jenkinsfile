/*
pipeline
*/

def BASE_DIR = "./deployment/k8s/helm"


pipeline {
    agent {
        node {
            label 'nimbus-cloud'
        }
    }

    environment {
        K8S_VERSION = "v1.10.8"
        BASE_DIR = "./deployment/k8s/helm"
        CASCADE_CONFIG="./"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/develop']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [[$class: 'SubmoduleOption',
                                      disableSubmodules: false,
                                      parentCredentials: false,
                                      recursiveSubmodules: true,
                                      reference: '',
                                      trackingSubmodules: false,
                                      [$class: 'CleanBeforeCheckout']],
                        submoduleCfg: [],
                        userRemoteConfigs: [[credentialsId: 'photon-automation', refspec: 'refs/heads/develop:refs/heads/develop', url: 'git@gitlab.eng.vmware.com:cna/audit-trail.git']]
                ])
            }
        }

        stage('Build'){
            steps {
                sh '''
                    cat > .hmakerc <<EOF
                    format: hypermake.v0
                    settings:
                        docker:
                            cache: false
EOF'''
                sh 'hmake build test check -R'


                script {
                    # Remove dangling docker images if they exist
                    docker_image_ids=$(docker images -f "dangling=true" -q)
                    if [ -n "$docker_image_ids" ]; then
                      echo $docker_image_ids | xargs docker rmi
                    fi
                }

            }
        }

        stage('UnitTest'){

            environment {
                    AUDIT_S3_BUCKET_NAME = "vmw-audit-trail-k8s-test"
                    AUDIT_EVENT_STREAM_NAME="vmw-audit-trail-stream-k8s-test"
                    K8S_DEPLOYMENT=true
            }

            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'cascade-test']]) {
                         sh './bin/linux/audit-trail-test'
                         echo 'PASS Integration Test'
                }

                script {
                    BUILT_IMAGE_VERION = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "image version $BUILT_IMAGE_VERION"
                }
            }
        }

        stage('PushImage') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'bintray-user',
                        usernameVariable: 'BINTRAY_USER', passwordVariable: 'BINTRAY_API_TOKEN']]) {
                    sh 'docker login -u $BINTRAY_USER -p $BINTRAY_API_KEY vmware-docker-audit-trail.bintray.io'
                    sh 'docker tag audit-trail:test vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERION'
                    sh 'docker push vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERION'
                    echo 'push image to registry'
                }
            }
        }

        stage('DeployToUnstable') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                      echo 'deploy image $BUILT_IMAGE_VERION to unstable'
                      sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/unstable'
                      sh '$BASE_DIR/upgrade_cluster.sh unstable $BUILT_IMAGE_VERION'
                }
            }
        }

        stage('TriggerIntegrationTest') {
            steps {
                echo "trigger audit trail e2e test job"
                build job: 'audit-trail-e2e', propagate: true, wait: true
            }
        }

        stage('DeployToStable') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                       echo 'deploy image $BUILT_IMAGE_VERION to stable'
                       sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/stable'
                       sh '$BASE_DIR/upgrade_cluster.sh stable $BUILT_IMAGE_VERION'
                }
            }
        }

        stage('DeployToStaging') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                        echo 'deploy image $BUILT_IMAGE_VERION to staging'
                        sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/staging'
                        sh '$BASE_DIR/upgrade_cluster.sh staging $BUILT_IMAGE_VERION'
                }
            }
        }

        stage('DeployToProd') {

            when {
                allOf {
                    environment ignoreCase: true, name: 'DeployToProd', value: 'yes'
                }
            }

            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-prod',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {
                        // upgrade to three production region.
                        echo 'deploy image $BUILT_IMAGE_VERION to prod-west-2'
                        sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/prod-us-west-2'
                        sh '$BASE_DIR/upgrade_cluster.sh prod-us-west-2 $BUILT_IMAGE_VERION'

                        echo 'deploy image $BUILT_IMAGE_VERION to prod-us-east-1'
                        sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/prod-us-east-1'
                        sh '$BASE_DIR/upgrade_cluster.sh prod-us-west-2 $BUILT_IMAGE_VERION'

                        echo 'deploy image $BUILT_IMAGE_VERION to prod-eu-west-1'
                        sh '$BASE_DIR/auth_cluster.sh $BASE_DIR/vke_cluster/prod-eu-west-1'
                        sh '$BASE_DIR/upgrade_cluster.sh prod-us-west-2 $BUILT_IMAGE_VERION'
                }
            }

        }
    } // end of stages

    post {
        failure {
        mail to: '$env.mailList',
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "AuditTrail Pipeline failed, please check ${env.BUILD_URL}"
        }
    }
} // end of pipeline
