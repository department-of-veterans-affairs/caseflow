## What is Caseflow Certification?

Caseflow Certification is a web-based tool that pre-fills the electronic Form 8 for paperless appeals and checks case documents for readiness for certification.

![Screenshot of Caseflow Certification ](certification.png "Caseflow Certification")

### How to Enter Caseflow Certification
1. Click on this link for the Demo to open. http://dsva-appeals-certification-demo-1715715888.us-gov-west-1.elb.amazonaws.com/test/users
2. On the dropdown menu User Selector, click 'Certify Appeal at 283'.
3. On App Selector tab, select Certification.
4. Select 'New' from the Certification tab to open tha application.

### (For developers) How to run unit tests in Certification
It is always good practise to run unit tests everytime you introduce a new or change a feature. Here is how you run some of the unit tests:

* In order to run tests for starts certification as a user who is not logged in, a user who is not authorized to login, a user who is authorized to login, run `bundle exec rspec spec/feature/certification/start_certification_spec.rb`.
* In order to run tests for save Certification as an authorized user, save certification data in the database, confirm validation works, run unit test 
`bundle exec rspec spec/feature/certification/save_certification_spec.rb`.
* In order to run tests for the CertificationV2 Stats Dashboard, run `bundle exec rspec spec/feature/certification/certification_v2_stats_spec.rb`.
* In order to run tests for the Certification Stats Dashboard, run `bundle exec rspec spec/feature/certification/certification_stats_spec.rb`.
* In order to run tests to cancel certification as authorized user, run `bundle exec rspec spec/feature/certification/cancel_certification_spec.rb`.

