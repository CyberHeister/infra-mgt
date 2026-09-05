pipeline {
    agent any

    environment {
        APP_NAME = 'my-app'
        IMAGE_NAME = "${APP_NAME}:${BUILD_NUMBER}"

        // Tells Terraform it is running unattended: suppresses the interactive
        // "run terraform init" style suggestions and colour codes in logs.
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = '0'
        TF_DIR = 'terraform'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'

                // Replace with your project's build command
                sh '''
                    if [ -f package.json ]; then
                        npm ci
                        npm run build
                    elif [ -f requirements.txt ]; then
                        echo "Python project detected"
                        python3 -m venv .venv
                        . .venv/bin/activate
                        pip install -r requirements.txt
                    elif [ -f pom.xml ]; then
                        ./mvnw clean package || mvn clean package
                    elif [ -f build.gradle ]; then
                        ./gradlew build || gradle build
                    else
                        echo "No known build system detected"
                    fi
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'

                sh '''
                    if [ -f package.json ]; then
                        npm test
                    elif [ -f pytest.ini ] || [ -d tests ]; then
                        . .venv/bin/activate 2>/dev/null || true
                        pytest
                    elif [ -f pom.xml ]; then
                        ./mvnw test || mvn test
                    elif [ -f build.gradle ]; then
                        ./gradlew test || gradle test
                    else
                        echo "No test framework detected"
                    fi
                '''
            }
        }

        stage('Docker Build') {
            when {
                expression {
                    fileExists('Dockerfile')
                }
            }

            steps {
                echo "Building Docker image: ${IMAGE_NAME}"

                sh """
                    docker build \
                        -t ${IMAGE_NAME} \
                        -t ${APP_NAME}:latest \
                        .
                """
            }
        }

        // ------------------------------------------------------------------
        // Terraform
        //
        // AWS AUTHENTICATION IS NOT WIRED UP YET. Pick one mechanism and apply
        // it to the stages below before this can reach AWS:
        //
        //   1. EC2 instance profile - agent runs on EC2 with an attached IAM
        //      role. Nothing to add here; the SDK picks the role up. No
        //      long-lived secrets. Only works if the agent is on EC2.
        //
        //   2. OIDC assume-role - the Jenkins OIDC / aws-credentials plugin
        //      exchanges a short-lived token for a role. Wrap the inner stages:
        //          withAWS(role: 'jenkins-terraform', roleAccount: '<acct>') { ... }
        //      No long-lived secrets, works off EC2, needs an IAM OIDC provider.
        //
        //   3. Static keys - wrap the inner stages:
        //          withCredentials([usernamePassword(
        //              credentialsId: 'aws-terraform',
        //              usernameVariable: 'AWS_ACCESS_KEY_ID',
        //              passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) { ... }
        //      Simplest to stand up; long-lived secrets needing manual rotation.
        // ------------------------------------------------------------------
        stage('Terraform') {
            when {
                // Skips the whole block until backend.tf has had its placeholder
                // bucket replaced with the real one from the bootstrap stack.
                // Without this gate, every build before bootstrap runs would go
                // red on `terraform init` for a reason unrelated to the commit.
                expression {
                    return fileExists("${env.TF_DIR}/backend.tf") &&
                           !readFile("${env.TF_DIR}/backend.tf").contains('REPLACE_ME')
                }
            }

            stages {

                stage('Format') {
                    steps {
                        // Run from the repository root, not TF_DIR, so bootstrap/
                        // is checked too.
                        sh 'terraform fmt -check -recursive'
                    }
                }

                stage('Init') {
                    steps {
                        dir("${env.TF_DIR}") {
                            sh 'terraform init -input=false'
                        }
                    }
                }

                stage('Validate') {
                    steps {
                        dir("${env.TF_DIR}") {
                            sh 'terraform validate'
                        }
                    }
                }

                stage('Plan') {
                    steps {
                        dir("${env.TF_DIR}") {
                            sh 'terraform plan -input=false -out=tfplan'
                            sh 'terraform show -no-color tfplan > tfplan.txt'
                        }

                        // Archived inside the stage, which runs before the
                        // cleanWs() in post.always, so the readable plan
                        // survives the workspace wipe.
                        archiveArtifacts artifacts: "${env.TF_DIR}/tfplan.txt", fingerprint: true
                    }
                }

                stage('Apply') {
                    when {
                        // branch is only populated by Multibranch Pipeline jobs.
                        // In a plain pipeline job this evaluates false and Apply
                        // is skipped - the safe direction to fail.
                        branch 'main'
                    }

                    steps {
                        // The approval sits outside any credential binding so a
                        // pending review does not hold a credential lease open.
                        timeout(time: 30, unit: 'MINUTES') {
                            input message: 'Apply the archived plan to AWS?', ok: 'Apply'
                        }

                        dir("${env.TF_DIR}") {
                            // Applies the SAVED plan, not a fresh one, so the
                            // approved change is exactly the change that lands.
                            // Re-planning here would let drift slip in between
                            // review and execution.
                            sh 'terraform apply -input=false tfplan'
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully."
        }

        failure {
            echo "Pipeline failed."
        }

        always {
            echo "Cleaning workspace..."
            cleanWs()
        }
    }
}
