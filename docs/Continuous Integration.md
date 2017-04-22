#Continuous Integration in Travis CI
Caseflow uses Travis CI as its hosted, distributed continuous integration service to build and test software projects hosted at GitHub.  When ever a pull request is created, it will automatically create a build on Travis CI. That build will run the `bundle exec rake` command, which runs all linters, security scans, unit tests, and feature tests for the project. All code must have a successful build in Travis CI before it can be merged into master.

Following are links to view the results for each product in Travis CI as well as a link to the product's repository:

| Product | GitHub Repository | Travis CI |
| --- | --- | ---|
| Caseflow | [casflow](https://github.com/department-of-veterans-affairs/caseflow) | [Travis CI - Caseflow](https://travis-ci.org/department-of-veterans-affairs/caseflow) |
| eFolder Express | [caseflow-efolder](https://github.com/department-of-veterans-affairs/caseflow-efolder) | [Travis CI - eFolder](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder) |
| Caseflow Feedback | [caseflow-feedback](https://github.com/department-of-veterans-affairs/caseflow-feedback) | [Travis CI - Caseflow Feedback](https://travis-ci.org/department-of-veterans-affairs/caseflow-feedback) |
| Commons | [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons) | [Travis CI - Commons](https://travis-ci.org/department-of-veterans-affairs/caseflow-commons) |
