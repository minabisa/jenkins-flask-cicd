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
          
          # Run container on the host's port 5000
          docker run -d --name flask-app -p 5000:5000 --restart always ${IMAGE}:${VERSION}

          # FIND THE HOST IP: 
          # Since Jenkins is in a container, localhost refers to Jenkins.
          # We find the gateway IP (172.17.0.1) to reach the host's port 5000.
          HOST_IP=\$(ip route show | grep default | awk '{print \$3}')
          echo "Detected Host Gateway IP: \$HOST_IP"

          echo "Waiting for Flask to be ready on http://\$HOST_IP:5000/ ..."
          
          NEXT_WAIT_TIME=0
          # Retry loop: checks every 2 seconds, up to 15 times (30 seconds total)
          until [ \$NEXT_WAIT_TIME -eq 15 ] || curl -s -f http://\$HOST_IP:5000/; do
            echo "App not ready yet... sleeping 2s"
            sleep 2
            NEXT_WAIT_TIME=\$((NEXT_WAIT_TIME+1))
          done

          # Final check - if this fails, the whole stage fails
          echo "Performing final health check..."
          curl -f http://\$HOST_IP:5000/
        """
      }
    }
  }

  post {
    success {
      slackSend(
        color: '#36a64f', 
        message: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed and verified! 🚀"
      )
    }
    failure {
      // Capture logs for debugging if the health check fails
      sh "docker logs flask-app || true"
      slackSend(
        color: '#FF0000', 
        message: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} failed. Check logs for details."
      )
    }
  }
}