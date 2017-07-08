podTemplate(cloud:'minikube', label:'caseflow-pod-alan', containers: [
    containerTemplate(
        name: 'postgres', 
        image: 'postgres:9.5',
        ttyEnabled: true,
        privileged: false,
        alwaysPullImage: false,
        envVars: [
            containerEnvVar(key: 'POSTGRES_PASSWORD', value: '1234')
        ]        
        ),
    containerTemplate(
        name: 'redis', 
        image: 'redis:3.2.9-alpine', 
        ttyEnabled: true,
        privileged: false,
        alwaysPullImage: false
    ),
     containerTemplate(
        name: 'ubuntu',
        image: 'kube-registry.kube-system.svc.cluster.local:31000/caseflow-pr-image-alan:2',
        ttyEnabled: true,
        alwaysPullImage: true,
        envVars: [
            containerEnvVar(
                key: 'DATABASE_URL', 
                value: 'postgres://postgres:1234@localhost:5432/caseflow_certification'),
            containerEnvVar(
                key: 'RAILS_ENV', 
                value: 'test')
        ]
        )]){
    node('caseflow-pod-alan') {

        stage('Clone repository') {
            container('ubuntu') {
                checkout scm
            }
        }

        stage('Test Setup') {
            container('ubuntu') {
                sh """
                Xvfb :99 -screen 0 1024x768x16 &
                export DISPLAY=:99
                cd ./client && npm install --no-optional && cd ..
                bundle install --without production staging
                RAILS_ENV=test bundle exec rake db:create
                RAILS_ENV=test bundle exec rake db:schema:load
                """
            }
        }

        stage('Execute Tests') {
            container('ubuntu') {
                sh"""
                RAILS_ENV=test bundle exec rake spec
                RAILS_ENV=test bundle exec rake ci:other
                """
            }
        }
    }
}