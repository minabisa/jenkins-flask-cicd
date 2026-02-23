pipeline {
  agent any

  environment {
    IMAGE = "minabisa90/flask-ci"
    VERSION = "v2"
  }

  stages {
    stage('Build') {
      steps {
        sh "docker build -t ${IMAGE}:${VERSION} ."
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh """
            echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
            docker push ${IMAGE}:${VERSION}
            docker logout
          """
        }
      }
    }

    stage('Deploy & Health Check') {
      steps {
        sh """
          set -e
          echo "Pulling latest image..."
          docker pull ${IMAGE}:${VERSION}

          echo "Restarting container..."
          docker rm -f flask-app || true
          
          # Run container
          docker run -d --name flask-app -p 5000:5000 --restart always ${IMAGE}:${VERSION}

          echo "Waiting for Flask to be ready..."
          # Retry loop: checks every 2 seconds, up to 10 times
          NEXT_WAIT_TIME=0
          until [ \$NEXT_WAIT_TIME -eq 10 ] || curl -s -f http://localhost:5000/; do
            echo "App not ready yet... sleeping 2s"
            sleep 2
            NEXT_WAIT_TIME=\$((NEXT_WAIT_TIME+1))
          done

          # Final check to fail the build if still down
          curl -f http://localhost:5000/
        """
      }
    }
  }

  post {
    success {
      slackSend(color: '#36a64f', message: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed!")
    }
    failure {
      // Diagnostic: Post logs to Slack or Jenkins console if it fails
      sh "docker logs flask-app || true"
      slackSend(color: '#FF0000', message: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} failed.")
    }
  }
}