pipeline {
  agent any

  environment {
    IMAGE = "minabisa90/flask-ci"
    // Use the short SHA as the unique version tag
  }

  stages {
    stage('Checkout') {
      steps { 
        checkout scm 
      }
    }

    stage('Build') {
      steps {
        script {
          // Get the short SHA to use as a precise tag
          env.SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          sh """
            docker build -t ${IMAGE}:${SHA} .
            docker tag ${IMAGE}:${SHA} ${IMAGE}:latest
          """
        }
      }
    }

    stage('Smoke Test') {
      steps {
        sh """
          # 1. Ensure the network exists
          docker network create ci || true

          # 2. Clean up any leftover container
          docker rm -f testflask || true

          # 3. Start the app on the 'ci' network
          docker run -d --name testflask --network ci ${IMAGE}:${SHA}

          # 4. Wait for startup
          echo "Waiting for Flask to start..."
          sleep 5

          # 5. Run curl FROM a sidecar container on the SAME network
          # This container can resolve the name 'testflask' via Docker DNS
          docker run --rm --network ci alpine/curl curl -f http://testflask:5000/ || (docker logs testflask && exit 1)
        """
      }
      post {
        always {
          // Always remove the test container to free up the name for the next build
          sh "docker rm -f testflask || true"
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh """
            echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
            docker push ${IMAGE}:${SHA}
            docker push ${IMAGE}:latest
            docker logout
          """
        }
      }
    }
  }

  post {
    failure {
      echo "❌ Pipeline failed. Check the Smoke Test logs."
    }
  }
}