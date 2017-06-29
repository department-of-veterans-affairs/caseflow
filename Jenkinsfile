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
    ),
    containerTemplate(
        name: 'ubuntu', 
        image: 'ruby:2.2.4', 
        ttyEnabled: true, 
        command: 'cat'
    )]) {
    node('caseflow-pod') {
        stage('before install') {
            container('ubuntu') {
                sh """
                wget https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/node-v6.10.2-linux-x64.tar.xz -O node-v6.10.2-linux-x64.tar.xz
                tar xf node-v6.10.2-linux-x64.tar.xz -C $PWD
                export PATH=$PWD/node-v6.10.2-linux-x64/bin:$PATH
                node -v
                sudo apt-get update
                wget https://s3-us-gov-west-1.amazonaws.com/dsva-appeals-devops/chromium-chromedriver_53.0.2785.143-0ubuntu0.14.04.1.1145_amd64.deb -O $PWD/chromium-chromedriver.deb
                sudo dpkg -i $PWD/chromium-chromedriver.deb
                sudo apt-get install -f
                """
            }
        }

        stage('before script') {
            container('ubuntu') {
                sh """
                node -v
                npm -v
                cd ./client && npm install --no-optional
                sudo apt-get install pdftk
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
            container('ubuntu') {
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