# What is Caseflow Certification?

Caseflow Certification is a web-based tool that pre-fills the electronic Form 8 for paperless appeals and checks case documents for readiness for certification.

![Screenshot of new Certification](certification.png "Certification")

## Certification (Dev Mode)

To log into Cetification from the welcome gate page, please follow the following steps:

1. On 'User Selector' dropdown menu, select Certify Appeal at 283.

1. Click the 'Switch user' button.
 
1. On the 'App Selector' tab, Select Certification to view the various pages in the workflow. 

1. To get to the various pages in the workflow, click on one of these five URLs of dummy data that we have a set up.

    - [http://localhost:3000/certifications/new/123C](http://localhost:3000/certifications/new/123C) is an appeal that is ready to certify.
    -  [http://localhost:3000/certifications/new/456C](http://localhost:3000/certifications/new/456C) is an appeal with mismatched docs.
    - [http://localhost:3000/certifications/new/789C](http://localhost:3000/certifications/new/789C) is an appeal that is already certified.
    - [http://localhost:3000/certifications/new/000ERR](http://localhost:3000/certifications/new/000ERR) is an appeal that raises a vbms error.
    - [http://localhost:3000/certifications/new/001ERR](http://localhost:3000/certifications/new/001ERR) is an appeal that is missing data.
   
####  Welcome Gate

   ![Screenshot of welcome page](welcome-gate.png "Welcome Gate")
   

## Running tests

To run the test suite:

    rake


### Running unit tests

 To run a test that starts certification as a user who is not logged in, a user who is not authorized to login, a user who is authorized to login:

     bundle exec rspec spec/feature/certification/start_certification_spec.rb

To run tests for save Certification as an authorized user, save certification data in the database, confirm validation works:

     bundle exec rspec spec/feature/certification/save_certification_spec.rb 

 To run tests for the CertificationV2 Stats Dashboard:

    bundle exec rspec spec/feature/certification/certification_v2_stats_spec.rb

 To run tests for the Certification Stats Dashboard:

     bundle exec rspec spec/feature/certification/certification_stats_spec.rb

 To run tests to cancel certification as authorized user:

      bundle exec rspec spec/feature/certification/cancel_certification_spec.rb



