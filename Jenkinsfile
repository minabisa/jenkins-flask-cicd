pipeline {
  agent any

  environment {
    IMAGE = "minabisa90/flask-ci"
    VERSION = "v2"
  }

  stages {

    stage('Build') {
      steps {
        sh """
          docker build -t ${IMAGE}:${VERSION} .
        """
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

    stage('Deploy to EC2 (same host)') {
      steps {
        sh """
          set -eux

          docker pull ${IMAGE}:${VERSION}
          docker rm -f flask-app || true
          docker run -d \\
            --name flask-app \\
            -p 5000:5000 \\
            --restart always \\
            ${IMAGE}:${VERSION}

          sleep 3
          curl -f http://localhost:5000/
        """
      }
    }
  }

  post {

    success {
      slackSend(
        color: '#36a64f',
        message: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed successfully! 🚀"
      )
    }

    failure {
      slackSend(
        color: '#FF0000',
        message: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} failed. Check Jenkins logs."
      )
    }

    unstable {
      slackSend(
        color: '#FFA500',
        message: "⚠️ UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
      )
    }
  }
}