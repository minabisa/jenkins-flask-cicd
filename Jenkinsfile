pipeline {
  agent any

  environment {
    IMAGE = "minabisa90/flask-ci"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        script {
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
          docker rm -f testflask || true
          docker run -d --name testflask -p 5000:5000 ${IMAGE}:${SHA}
          sleep 2
          curl -f http://localhost:5000/ || (docker logs testflask && exit 1)
          docker rm -f testflask
        """
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
}