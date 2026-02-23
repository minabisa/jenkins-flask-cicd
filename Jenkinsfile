pipeline {
  agent any

  environment {
    IMAGE = "minabisa90/flask-ci"
    VERSION = "v2"
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
      docker run -d --name testflask --network ci ${IMAGE}:${SHA}
      sleep 3
      curl -f http://testflask:5000/ || (docker logs testflask && exit 1)
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
    stage("Integration Test (Local)") {
      steps {
        sh '''
          # 1. Clean up any old container from a previous failed run
          docker rm -f testflask || true

          # 2. Start the container using host networking
          # This allows 'localhost' to work between Jenkins and the container
          docker run -d --name testflask --network host minabisa90/flask-ci:3050af2
          
          # 3. Wait for Flask to initialize
          echo "Waiting for Flask to start..."
          sleep 5
          
          # 4. Run the test
          echo "Checking Flask endpoint..."
          curl --retry 3 --retry-delay 5 http://localhost:5000
          
          # 5. Clean up after success
          docker rm -f testflask
        '''
      }
    }
   

  }
}