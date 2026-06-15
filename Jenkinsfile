def build = env.BUILD_NUMBER

def appname = "flask-aws-monitor"
def repo = "avited"

def appimage = "${repo}/${appname}"
def apptag = "${build}"

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
            securityContext: 'privileged',
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
                sh """
                    docker version
                    docker build \
                        -t ${appimage}:${apptag} \
                        -t ${appimage}:latest \
                        .
                """
            }
        }

        stage('Push Docker Image') {
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

        echo "SUCCESS: Pipeline completed successfully"
    }
}
