#!groovy

// This is a boilerplate script used by Jenkins to run the appeals-deployment
// pipeline. It clones the appeals-deployment repo and execute a file called
// common-pipeline.groovy.

// The application name as defined in appeals-deployment aws-config.yml
def APP_NAME = 'certification';

// The application version to check out.
// See http://docs.ansible.com/ansible/git_module.html version field
def APP_VERSION = env.APP_VERSION ?: 'HEAD';

def DEPLOY_MESSAGE = null

// Allows appeals-deployment branch (defaults to main) to be overridden for
// testing purposes
def DEPLOY_BRANCH = (env.DEPLOY_BRANCH != null) ? env.DEPLOY_BRANCH : 'main'

/************************ Common Pipeline boilerplate ************************/

def commonPipeline;
node('deploy') {

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

    if (env.APP_ENV == 'prod') {
      stage('deploy-message') {
        checkout scm
        DEPLOY_MESSAGE = sh (
          // this script will:
          // get the latest `deployed` release created by: https://github.com/department-of-veterans-affairs/appeals-deployment/blob/main/ansible/utility-roles/deployed-version/files/tag_deployed_commit.py
          // compare current HEAD commit to the last deployed release
          // save the message to be announced in Slack by the pipeline
          script: "git log \$(git ls-remote --tags https://${env.GIT_CREDENTIAL}@github.com/department-of-veterans-affairs/caseflow.git \
                   | awk '{print \$2}' | grep -E 'deployed' \
                   | sort -t/ -nk4 \
                   | awk -F\"/\" '{print \$0}' \
                   | tail -n 1 \
                   | awk '{print \$1}')..HEAD --pretty='format:%h %<(15)%an %s'",
          returnStdout: true
        ).trim()
      }
    }

    // Checkout the deployment repo for the ansible script. This is needed
    // since the deployment scripts are separated from the source code.
    stage ('pull-deploy-repo') {

      sh "git clone --depth 1 -b $DEPLOY_BRANCH https://${env.GIT_CREDENTIAL}@github.com/department-of-veterans-affairs/appeals-deployment"
      dir ('./appeals-deployment/ansible') {
        // The commmon pipeline script should kick off the deployment.
        commonPipeline = load "../jenkins/common-pipeline.groovy"
      }
    }
  }
}

// Execute the common pipeline.
// Note that this must be outside of the node block since the common pipeline
// runs another set of stages.
if (env.COMMON_PIPELINE_TASK == 'bake') {
  commonPipeline.bake(APP_NAME, APP_VERSION, DEPLOY_MESSAGE);
} else if (env.COMMON_PIPELINE_TASK == 'build') {
  commonPipeline.build(APP_NAME, APP_VERSION, DEPLOY_MESSAGE);
} else if (env.COMMON_PIPELINE_TASK == 'deploy'){
  commonPipeline.deploy(APP_NAME, APP_VERSION, DEPLOY_MESSAGE);
}
