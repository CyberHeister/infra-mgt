pipeline {
    agent any

    environment {
        APP_NAME = 'my-app'
        IMAGE_NAME = "${APP_NAME}:${BUILD_NUMBER}"
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
