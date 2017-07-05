podTemplate(cloud:'minikube', label:'caseflow-pod', containers: [
    containerTemplate(
        name: 'postgres', 
        image: 'postgres:9.5',
        ttyEnabled: true,
        command: 'cat',
        privileged: false,
        alwaysPullImage: false
        ),
    containerTemplate(
        name: 'redis', 
        image: 'redis:3.2.9-alpine', 
        ttyEnabled: true,
        command: 'cat',
        privileged: false,
        alwaysPullImage: false
    )] {
    node('caseflow-pod') {
        def app

        stage('Clone repository') {
            /* Let's make sure we have the repository cloned to our workspace */

            checkout scm
        }

        stage('Build image') {
            /* This builds the actual image; synonymous to
             * docker build on the command line */

            app = docker.build("getintodevops/hellonode")
        }

        stage('Test Setup') {
            app.inside {
                sh """
                echo $PATH
                apt-get update
                apt-get install -y chromedriver pdftk xvfb
                printenv
                node -v
                npm -v
                cd ./client && npm install --no-optional
                RAILS_ENV=test bundle exec rake db:create
                RAILS_ENV=test bundle exec rake db:schema:load
                export PATH=$PATH:/usr/lib/chromium-browser/
                export DISPLAY=:99.0
                sh -e /etc/init.d/xvfb start
                sleep 3
                """
            }
        }

        stage('script') {
            app.inside {
                sh"""
                bundle exec rake spec
                bundle exec rake ci:other
                mv node_modules node_modules_bak && npm install --production --no-optional && npm run build:production
                - rm -rf node_modules && mv node_modules_bak node_modules
                """
            }
        }
    }
}