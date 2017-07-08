podTemplate(
    cloud:'minikube',
    label:'caseflow-test-runner-artem',
    containers: [
    	containerTemplate(
        	name: 'postgres', 
        	image: 'postgres:9.5',
        	ttyEnabled: true,
       		privileged: false,
		envVars: [
			 containerEnvVar(key: 'POSTGRES_USER', value: 'root')
			 ],
        	alwaysPullImage: false
        ),
    	containerTemplate(
		name: 'redis', 
        	image: 'redis:3.2.9-alpine', 
        	ttyEnabled: true,
        	privileged: false,
        	alwaysPullImage: false
    	),
     	containerTemplate(
		name: 'caseflow-test-runner',
        	image: 'kube-registry.kube-system.svc.cluster.local:31000/caseflow-test-runner',
        	ttyEnabled: true,
		alwaysPullImage: true,
		envVars: [
			 containerEnvVar(key: 'RAILS_ENV', value: 'test'),
    			 containerEnvVar(key: 'POSTGRES_USER', value: 'root'),
    			 containerEnvVar(key: 'POSTGRES_HOST', value: 'localhost'),
    			 containerEnvVar(key: 'REDIS_URL_CACHE', value: 'redis://localhost:6379/0/cache/')
			 ],
        	command: 'cat'
    	)
    ]) {
    
    node('caseflow-test-runner-artem') {

        stage('Clone repository') {
            container('caseflow-test-runner') {
                checkout scm
            }
        }

        stage('Test Setup') {
            container('caseflow-test-runner') {
                sh '''
		echo $POSTGRES_HOST
		echo $POSTGRES_USER
		echo $RAILS_ENV
		bundle install --deployment --without production staging development
		cd client && npm install --no-optional
		cd ..
		bundle exec rake db:create
		bundle exec rake db:schema:load
                '''
            }
        }

        stage('Execute Tests') {
            container('caseflow-test-runner') {
                sh '''
		Xvfb :99 -screen 0 1024x768x16 &> xvfb.log &
     	 	export DISPLAY=:99
		bundle exec rake
		bundle exec rake ci:other
                '''
            }
        }
    }
}