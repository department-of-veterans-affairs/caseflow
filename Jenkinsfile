#!groovy

// This file is executed by the Jenkins pipeline. Each stage in the pipeline
// is executed in a serial manner.
//
// Beware that this script is executed under the Jenkins sandbox. If your
// script is being rejected, it is likely that you will have to approve
// the API signatures manually.
//
// See https://wiki.jenkins-ci.org/display/JENKINS/Script+Security+Plugin#ScriptSecurityPlugin-User%E2%80%99sguide

// Helper function to call slackSend, which is part of the Jenkins Slack plugin.
// See https://jenkins.io/doc/pipeline/steps/slack/
def notify(message, color='good') {
    slackSend message: message,
              color: color,
              channel: env.SLACK_CHANNEL,
              teamDomain: env.SLACK_TEAM_DOMAIN,
              token: env.SLACK_TOKEN,
              failOnError: true
}

node {
  // Default to UAT environment, but allow Jenkins to override this in
  // environment variables.
  def APP_ENV;
  if(env.APP_ENV) {
    APP_ENV = env.APP_ENV
  } else {
    APP_ENV = 'uat'
    print "APP_ENV is not defined, defaulting to ${APP_ENV}"
  }

  def APP_NAME = 'certification';
  def APP_VERSION = 'HEAD'

  // withCredentials allows us to expose the secrets in Credential Binding
  // Plugin to get the credentials from Jenkins secrets.
  withCredentials([
    [
      // Token to access the appeals deployment repo.
      $class: 'StringBinding',
      credentialsId : 'GIT_CREDENTIAL',
      variable: 'GIT_CREDENTIAL',
    ],
    [
      // Used to decrypt the Ansible vault pass files.
      $class: 'StringBinding',
      credentialsId : 'VAULT_PASS',
      variable: 'VAULT_PASS',
    ],
    [
      // API token to integrate with Slack channel.
      $class: 'StringBinding',
      credentialsId : 'SLACK_TOKEN',
      variable: 'SLACK_TOKEN',
    ],
    [
      // API token to integrate with Slack channel.
      $class: 'StringBinding',
      credentialsId : 'SLACK_TEAM_DOMAIN',
      variable: 'SLACK_TEAM_DOMAIN',
    ],
    [
      // API token to integrate with Slack channel.
      $class: 'StringBinding',
      credentialsId : 'SLACK_CHANNEL',
      variable: 'SLACK_CHANNEL',
    ]
  ])
  {
    try {
      // Clean up the workspace before each job. It enforces a clean start.
      stage('cleanup') {
        step([$class: 'WsCleanup'])
      }

      // Notify Slack that a build has started.
      stage('notify-slack-start') {
        notify """Deploying `${APP_NAME}` to `${APP_ENV}`.
                 |${currentBuild.rawBuild.getCauses()[0].getShortDescription()}
                 |${currentBuild.getAbsoluteUrl()}""".stripMargin()
      }

      // Checkout the deployment repo for the ansible script. This is needed
      // since the deployment scripts are separated from the source code.
      stage ('checkout-deploy-repo') {
        sh "git clone https://${env.GIT_CREDENTIAL}@github.com/department-of-veterans-affairs/appeals-deployment"
        dir ('./appeals-deployment') {
          sh 'git submodule init'
          sh 'git submodule update'
        }
      }

      // Execute the ansible playbook to deploy the AMI. This stage will take
      // awhile to complete.
      stage ('deploy') {
        // dir ('./appeals-deployment') {
        //   sh "echo \"${env.VAULT_PASS}\" | \
        //     ansible-playbook deploy-to-aws.yml \
        //       --verbose \
        //       -i localhost \
        //       -e app_name=${APP_NAME} \
        //       -e deploy_env=${APP_ENV} \
        //       -e app_version=${APP_VERSION} \
        //       --vault-password-file=/bin/cat"
        // }
      }

      // Notify Slack that the job has completed.
      stage('notify-slack-complete') {
        notify """Successfully deployed `${APP_NAME}` to `${APP_ENV}`.
                 |Took ${currentBuild.rawBuild.getDurationString()}""".stripMargin()
      }
    } catch (err) {
      // Notify Slack for any failures
      stage('notify-slack-failure') {
        def message = """Failed to deploy `${APP_NAME}` to `${APP_ENV}`!
        |Reason: `${err}`
        |${currentBuild.getAbsoluteUrl()}console""".stripMargin()

        notify message, 'danger'
        error(message)
      }
    }
  }
}
