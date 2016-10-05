#!groovy

node {

    try {

       stage 'Checkout'
            checkout scm

       stage 'Build'

            print "Running Build"
            sh 'bundle install'
       }


    catch (err) {

        throw err
    }

}
