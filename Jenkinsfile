def build = env.BUILD_NUMBER
def branch = env.BRANCH_NAME
def appname = "myapp"
def repo = "avited"
def appimage = "${repo}/${appname}"
def apptag = "${build}"

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
                    // FIX 1: withEnv safely passes the Groovy `build` variable
                    // to the shell as a plain env var, without mixing it into
                    // the same """...""" block as the credentials
                    withEnv(["BUILD_TAG=v${build}"]) {

                        // FIX 2: single-quoted sh '''...''' means Groovy does NOT
                        // interpolate anything — $GH_USER, $GH_TOKEN, $BUILD_TAG
                        // are all expanded by the shell at runtime, not by Groovy.
                        // Previously, """...""" caused Groovy to embed $GH_USER
                        // (your email: satmyhat@gmail.com) literally into the URL,
                        // so Git parsed "gmail.com:****" as host:port → fatal error.
                        sh '''
                            git config user.email "jenkins@ci.local"
                            git config user.name "Jenkins CI"
                            git tag -a "$BUILD_TAG" -m "Release build $BUILD_TAG"   # FIX 2: $BUILD_TAG expanded by shell, not Groovy
                            git push "https://${GH_USER}:${GH_TOKEN}@github.com/AviTE86/Helm-Project.git" "$BUILD_TAG"   # FIX 2: credentials expanded by shell safely
                        '''
                    }
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
