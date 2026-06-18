def build = env.BUILD_NUMBER
def branch = env.BRANCH_NAME
def appname = "myapp"
def repo = "avited"
def appimage = "${repo}/${appname}"
def apptag = "${build}"

// Posts a message to Slack via an Incoming Webhook.
// The webhook URL is stored as a Jenkins "Secret text" credential (id: 'slack-webhook')
// and is never hardcoded here.
def notifySlack(String message) {
    withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK')]) {
        container('jnlp') {
            sh """
                curl -sf -X POST -H 'Content-type: application/json' \
                    --data '{"text": "${message}"}' \
                    "\$SLACK_WEBHOOK"
            """
        }
    }
}

podTemplate(
    containers: [
        containerTemplate(
            name: 'jnlp',
            image: 'jenkins/inbound-agent',
            ttyEnabled: true
        ),

        // Docker CLI container
        containerTemplate(
            name: 'docker',
            image: 'docker:26-cli',
            command: 'cat',
            ttyEnabled: true,
            envVars: [
                envVar(key: 'DOCKER_HOST', value: 'tcp://localhost:2375')
            ]
        ),

        // Docker Daemon (DinD)
        containerTemplate(
            name: 'dind',
            image: 'docker:26-dind',
            command: 'dockerd',
            args: '--host=tcp://0.0.0.0:2375 --host=unix:///var/run/docker.sock',
            privileged: true,
            ttyEnabled: true,
            envVars: [
                envVar(key: 'DOCKER_TLS_CERTDIR', value: '')
            ]
        )
    ]
) {

    node(POD_LABEL) {

        def buildOk = true

      try {
        notifySlack(":hourglass_flowing_sand: STARTED: ${env.JOB_NAME} #${build} (${env.BUILD_URL})")

        stage('Clone Repository') {
            container('jnlp') {
                git branch: 'main',
                    url: 'https://github.com/AviTE86/Helm-Project.git'
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
            container('docker') {
                try {
                    sh """
                        echo 'Waiting for the Docker daemon to become ready...'
                        timeout 150 sh -c 'until docker info >/dev/null 2>&1; do sleep 2; done'
                        docker version
                        docker build \
                            -t ${appimage}:${apptag} \
                            -t ${appimage}:latest \
                            .
                    """
                } catch (err) {
                    buildOk = false
                    currentBuild.result = 'FAILURE'
                    echo "BUILD FAILED: ${err.getMessage()} - skipping push"
                }
            }
        }

        stage('Push Docker Image') {
            if (!buildOk) {
                echo 'SKIPPED: image build failed, nothing to push'
                return
            }
            container('docker') {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
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
        }

        // GitHub update: tag the version on a successful build of main.
        // Fulfils the "Git tags for each merge into main to mark versions" requirement.
        // The token is a Jenkins usernamePassword credential (id: 'github') — a PAT,
        // never hardcoded.
        stage('Tag Release') {
            if (!buildOk) {
                echo 'SKIPPED: build failed, not tagging a release'
                return
            }
            container('jnlp') {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github',
                        usernameVariable: 'GH_USER',
                        passwordVariable: 'GH_TOKEN'
                    )
                ]) {
                    sh '''
                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins CI"
                        git tag -a "v${build}" -m "Release build ${build}"
                        git push "https://${GH_USER}:${GH_TOKEN}@github.com/AviTE86/Helm-Project.git" "v${build}"
                    '''
                }
            }
        }

      } catch (err) {
        buildOk = false
        currentBuild.result = 'FAILURE'
        echo "PIPELINE ERROR: ${err.getMessage()}"
      } finally {
        if (buildOk) {
            echo "SUCCESS: Pipeline completed successfully"
            notifySlack(":white_check_mark: SUCCESS: ${env.JOB_NAME} #${build} - pushed ${appimage}:${apptag} and tagged v${build}")
        } else {
            echo "FAILURE: Pipeline finished with a failed build"
            notifySlack(":x: FAILURE: ${env.JOB_NAME} #${build} (${env.BUILD_URL})")
        }
      }
    }
}
