#!/usr/bin/env groovy
/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

// The declarative agent is defined in yaml.  It was previously possible to
// define containerTemplate but that has been deprecated in favor of the yaml
// format
// Reference: https://github.com/jenkinsci/kubernetes-plugin

// set up pod label and GOOGLE_APPLICATION_CREDENTIALS (for Terraform)
def label = "k8s-infra"
def containerName = "k8s-node"
def CASSANDRA_VERSION = "3.11.3"
def REV = "v${env.BUILD_NUMBER}"
def IMAGE_TAG = "${CASSANDRA_VERSION}-${REV}"
def APP_NAME = 'cassandra'
def MANIFEST_FILE = 'manifests/cassandra-statefulset.yaml'
def GOOGLE_APPLICATION_CREDENTIALS    = '/home/jenkins/dev/jenkins-deploy-dev-infra.json'
// env.CLUSTER_ZONE will need to be updated to match the
// ZONE in the jenkins.propeties file
env.CLUSTER_ZONE = "${CLUSTER_ZONE}"
// env.PROJECT_ID will need to be updated to match your GCP
// development project id
env.PROJECT_ID = "${PROJECT_ID}"
env.REGION = "${REGION}"
def shortCommit = sh ( returnStdout: true, script: 'git rev-parse HEAD | cut -c 1-6').trim()
env.CLUSTER_NAME = "mycsharp-${shortCommit}"


podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: build-node
spec:
  containers:
  - name: ${containerName}
    image: gcr.io/pso-helmsman-cicd/jenkins-k8s-node:${env.CONTAINER_VERSION}
    command: ['cat']
    tty: true
    volumeMounts:
    # Mount the dev service account key
    - name: dev-key
      mountPath: /home/jenkins/dev
  volumes:
  # Create a volume that contains the dev json key that was saved as a secret
  - name: dev-key
    secret:
      secretName: jenkins-deploy-dev-infra
"""
 ) {
 node(label) {
  try {
    // Options covers all other job properties or wrapper functions that apply to entire Pipeline.
    properties([disableConcurrentBuilds()])
    // set env variable GOOGLE_APPLICATION_CREDENTIALS for Terraform
    env.GOOGLE_APPLICATION_CREDENTIALS=GOOGLE_APPLICATION_CREDENTIALS

    // Run our various linters against the project
    stage('Lint') {
        container(containerName) {
          sh "make all"
      }
    }

    // Setup the GCE access for Jenkins test run
    stage('Setup') {
        container(containerName) {
          // Setup gcloud service account access
          sh "gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}"
          sh "gcloud config set compute/zone ${env.CLUSTER_ZONE}"
          sh "gcloud config set core/project ${env.PROJECT_ID}"
          sh "gcloud config set compute/region ${env.REGION}"
          sh "gcloud config set container/cluster ${env.CLUSTER_NAME}"

         }
    }

   // Use Cloud Build to build our two containers
    stage('Build Containers') {
       container(containerName) {
          // You can use dir to set the working directory
          dir('container') {
            sh 'gcloud builds submit --config=cloudbuild.yaml --substitutions=_CASSANDRA_VERSION=${CASSANDRA_VERSION},_REV_=${REV} .'
          }
        }
    }


    // Update the manifest and build the Cassandra Cluster
    stage('Create') {
      steps {
        container(containerName) {
           timeout(time: 20, unit: 'MINUTES') {
             // update the cassandra image tag
             sh "./update_image_tag.sh ${PROJECT_ID} ${APP_NAME} ${IMAGE_TAG} ${MANIFEST_FILE}"
             sh "make create CLUSTER_NAME=${env.CLUSTER_NAME}"
             sh "sleep 360"
             // TODO add condition to test with `gcloud container clusters list --filter name=${env.CLUSTER_NAME} --format=value(status)` != "RUNNING" ]`
          }
        }
      }
    }

    // Validate the Cassandra Cluster
    stage('Validate') {
      steps {
        container(containerName) {
          script {
            for (int i = 0; i < 3; i++) {
               sh "make validate CLUSTER_NAME=${env.CLUSTER_NAME}"
            }
          }
        }
      }
    }
  }

  // Tear down everything
   catch (err) {
      stage('Teardown') {
        container(containerName) {
          sh "make delete CLUSTER_NAME=${env.CLUSTER_NAME}"
          sh 'gcloud auth revoke'
        }
      }
      // if any exception occurs, mark the build as failed
      // and display a detailed message on the Jenkins console output
      currentBuild.result = 'FAILURE'
      echo "FAILURE caught echo ${err}"
      throw err
   }
   finally {
     stage('Teardown') {
        container(containerName) {
          sh "make delete CLUSTER_NAME=${env.CLUSTER_NAME}"
          sh 'gcloud auth revoke'
        }
      }
    }
  }
}
