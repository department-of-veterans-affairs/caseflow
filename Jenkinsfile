#!groovy

// This is a boilerplate script used by Jenkins to run the appeals-deployment
// pipeline. It clones the appeals-deployment repo and execute a file called
// common-pipeline.groovy.

// The application name as defined in appeals-deployment aws-config.yml
def APP_NAME = 'certification';

// The application version to checkout.
// See http://docs.ansible.com/ansible/git_module.html version field
def APP_VERSION = 'HEAD'


/************************ Common Pipeline boilerplate ************************/

def commonPipeline;
node {

  // withCredentials allows us to expose the secrets in Credential Binding
  // Plugin to get the credentials from Jenkins secrets.
  withCredentials([
    [
      // Token to access the appeals deployment repo.
      $class: 'StringBinding',
      credentialsId : 'GIT_CREDENTIAL',
      variable: 'GIT_CREDENTIAL',
    ]
  ])
  {
    // Clean up the workspace so that we always start from scratch.
    stage('cleanup') {
      step([$class: 'WsCleanup'])
    }

    // Checkout the deployment repo for the ansible script. This is needed
    // since the deployment scripts are separated from the source code.
    stage ('checkout-deploy-repo') {
      sh "git clone https://${env.GIT_CREDENTIAL}@github.com/department-of-veterans-affairs/appeals-deployment"
      dir ('./appeals-deployment/ansible') {
        sh 'git submodule init'
        sh 'git submodule update'

        // The commmon pipeline script should kick off the deployment.
        commonPipeline = load "./jenkins/common-pipeline.groovy"
      }
    }
  }
}

// Execute the common pipeline.
// Note that this must be outside of the node block since the common pipeline
// runs another set of stages.
commonPipeline.deploy(APP_NAME, APP_VERSION);
