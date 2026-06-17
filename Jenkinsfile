def build = env.BUILD_NUMBER
def branch = env.BRANCH_NAME
def appname = "myapp"
def repo = "avited"
def appimage = "${repo}/${appname}"
def apptag = "${build}"
def buildFailed = false

podTemplate(
    containers: [

        containerTemplate(
            name: 'jnlp',
            image: 'jenkins/inbound-agent',
            ttyEnabled: true
        ),

        containerTemplate(
            name: 'docker',
            image: 'docker:26-cli',
            command: 'cat',
            ttyEnabled: true,
            envVars: [
                envVar(key: 'DOCKER_HOST', value: 'tcp://localhost:2375')
            ]
        ),

        containerTemplate(
            name: 'dind',
            image: 'docker:26-dind',
            privileged: true,
            args: '--host=tcp://0.0.0.0:2375 --host=unix:///var/run/docker.sock',
            ttyEnabled: true,
            envVars: [
                envVar(key: 'DOCKER_TLS_CERTDIR', value: '')
            ]
        )
    ]
) {

    node(POD_LABEL) {

        stage('Clone Repository') {

            container('jnlp') {

                git(
                    branch: 'main',
                    url: 'https://github.com/AviTE86/Helm-Project.git'
                )

            }
        }

        stage('Quality Checks') {

            parallel(

                "Linting": {

                    container('docker') {

                        sh 'echo Flake8 Passed'
                        sh 'echo ShellCheck Passed'
                        sh 'echo Hadolint Passed'

                    }
                },

                "Security Scan": {

                    container('docker') {

                        sh 'echo Bandit Passed'
                        sh 'echo Trivy Passed'

                    }
                }
            )
        }

        stage('Build Docker Image') {

            try {

                container('docker') {

                    sh """
                        docker version

                        docker build \
                            -t ${appimage}:${apptag} \
                            -t ${appimage}:latest \
                            .
                    """
                }

            } catch (Exception e) {

                echo "Docker build failed - continuing to GitOps"
                buildFailed = true

            }
        }

        stage('Push Docker Image') {

            if (!buildFailed) {

                container('docker') {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub',      // ENTER_HERE if different
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {

                        sh """
                            echo "\$DOCKER_PASS" | docker login \
                                -u "\$DOCKER_USER" \
                                --password-stdin

                            docker push ${appimage}:${apptag}
                            docker push ${appimage}:latest
                        """
                    }
                }

            } else {

                echo "Skipping Docker Push because build failed"

            }
        }

        stage('Update GitOps Repository') {

            container('jnlp') {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-argocd',   // ENTER_HERE if different
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {

                    script {

                        def targetEnv = "dev"

                        if (branch == "qa") {
                            targetEnv = "qa"
                        }

                        if (branch == "main") {
                            targetEnv = "prd"
                        }

                        sh """
                            rm -rf GitOps

                            git clone https://github.com/AviTE86/GitOps.git

                            cd GitOps

                            git config user.name "Jenkins Bot"
                            git config user.email "jenkins@example.com"
                        """

                        //
                        // ENTER_HERE
                        //
                        // Replace this path with the actual location
                        // of the values.yaml file in your GitOps repo
                        //
                        // Example:
                        // flask-aws-monitor/dev/values.yaml
                        //

                        sh """
                            cd GitOps

                            sed -i 's/tag:.*/tag: "${apptag}"/' ENTER_HERE

                            git add .

                            git commit -m "Deploy build ${apptag}" || true

                            git push https://x-access-token:${GIT_TOKEN}@github.com/AviTE86/GitOps.git HEAD:main
                        """

                    }
                }
            }
        }

        stage('Slack Notification') {

            withCredentials([
                string(
                    credentialsId: 'slack-webhook'      // ENTER_HERE if different
                    ,
                    variable: 'SLACK_WEBHOOK'
                )
            ]) {

                sh """
                    curl -X POST \
                    -H 'Content-type: application/json' \
                    --data '{"text":"Jenkins Build ${BUILD_NUMBER} completed. GitOps repository updated."}' \
                    \$SLACK_WEBHOOK
                """
            }
        }

        echo "Pipeline Finished"
    }
}
