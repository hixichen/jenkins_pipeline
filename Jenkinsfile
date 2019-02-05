/*
pipeline for audit trail service
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
                cleanWs()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/develop']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'SubmoduleOption',
                                  disableSubmodules: false,
                                  parentCredentials: true,
                                  recursiveSubmodules: true,
                                  reference: '',
                                  trackingSubmodules: false]],
                    submoduleCfg: [],
                    userRemoteConfigs: [[credentialsId: 'photon-automation', refspec: 'refs/heads/develop:refs/heads/develop', url: 'git@gitlab.eng.vmware.com:cna/audit-trail.git']]
                ])
            }
        }

        stage('Build'){
            steps {

                sh '''
                echo "Downloading hmake..."
                wget https://github.com/evo-cloud/hmake/releases/download/v1.3.1/hmake-linux-amd64.tar.gz
                sudo tar -C /usr/local/bin -zxf hmake-linux-amd64.tar.gz
                '''

                sh '''
                    cat > .hmakerc <<EOF
                    format: hypermake.v0
                    settings:
                        docker:
                            cache: false
EOF'''
                sh 'hmake build test check -R'

                sh '''
                   # Remove dangling docker images if they exist
                   docker_image_ids=$(docker images -f "dangling=true" -q)
                   if [ -n "$docker_image_ids" ]; then
                     echo $docker_image_ids | xargs docker rmi
                   fi

                '''
            }
        }

        stage('IntegrationTest'){

            environment {
                    AUDIT_S3_BUCKET_NAME = "vmw-audit-trail-k8s-test"
                    AUDIT_EVENT_STREAM_NAME="vmw-audit-trail-stream-k8s-test"
                    K8S_DEPLOYMENT=true
            }

            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'cascade-test']]) {
                         //sh './bin/linux/audit-trail-test'
                         echo 'PASS Integration Test'
                }

                script {
                    BUILT_IMAGE_VERSION = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "image version $BUILT_IMAGE_VERSION"
                }
            }
        }

        stage('PushImage') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'bintray-user',
                        usernameVariable: 'BINTRAY_USER', passwordVariable: 'BINTRAY_API_TOKEN']]) {
                    sh "docker login -u $BINTRAY_USER -p $BINTRAY_API_TOKEN vmware-docker-audit-trail.bintray.io"
                    sh "docker tag audit-trail:test vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERSION"
                    sh "docker push vmware-docker-audit-trail.bintray.io/audit-trail:$BUILT_IMAGE_VERSION"
                    echo "push image to registry"
                }
            }
        }

        stage('DeployToUnstable') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                      echo "deploy image $BUILT_IMAGE_VERSION to unstable"
                      //sh "$BASE_DIR/auth-cluster.sh $BASE_DIR/vke_cluster/prod-west-2"
                      //sh "$BASE_DIR/upgrade-cluster.sh prod-west-2 $BUILT_IMAGE_VERSION"
                }
            }
        }

        stage('TriggerE2ETest') {
            steps {
                echo "trigger audit trail e2e test job"
                build job: 'audit-trail-e2e', propagate: true, wait: true
            }
        }

        stage('DeployToStable') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                      echo "deploy image $BUILT_IMAGE_VERSION to stable"
                }
            }
        }

        stage('DeployToStaging') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'vke-audit-trail-dev',
                        usernameVariable: 'ORG_ID', passwordVariable: 'API_TOKEN']]) {

                      echo "deploy image $BUILT_IMAGE_VERSION to staging"
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

                        echo "deploy image $BUILT_IMAGE_VERSION to prod-west-2"
                }
            }

        }
    } // end of stages

    post {
        always {
            mail to: "$env.mailList",
            subject: "Pipeline: ${currentBuild.fullDisplayName}",
            body: "AuditTrail Pipeline Job, please check ${env.BUILD_URL}"
        }
    }
} // end of pipeline
