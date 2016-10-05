#!groovy

node {

    try {

       stage 'Checkout'
            checkout scm

       stage 'Build'

            print "Running Build"
            sh 'bundle install --production'
       }


    catch (err) {

        throw err
    }

}
