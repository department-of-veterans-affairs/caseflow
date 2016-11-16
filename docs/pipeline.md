#Testing and Deployment Pipeline

##Development
Code is developed on feature branches and merged into master via pull requests (PR's). It is encouraged that pull requests be focused, small, and merged into master frequently. 

Pull requests do not need to complete an issue or feature. If a feature is incomplete, [Feature Toggles](http://martinfowler.com/bliki/FeatureToggle.html) should be used if necessary to prevent users from accessing the incomplete feature. One easy (but crude) way to implement a feature flag is to gate the feature only to users with the "System Admin" function in CSS.

Additionally, PR's should be linked to their associated issues by adding the issue number in the PR description (like this: "#123"). Don't write "fixes #123", because that will automatically close the issue before it has been validated.

##Testing
There are two major types of tests written by developers as a part of committing new functionality:

**Unit tests** should test all logic paths broken down into the smallest possible pieces. For effective unit tests, functions should be well factored and written with as few dependencies and side effects as possible. Tests should avoid requiring DB reads and writes when possible, but should not shy away from them if the functionality being tested is coupled to the DB.

**Feature tests** use [Capybara](https://github.com/teamcapybara/capybara) to test flows of the application using the UI, in isolation from it's external system dependencies (like SSO). All major system flows should be covered, but don't be afraid to test multiple things in one test, since the setup and teardown costs of these tests are high. (Note: As an added bonus, we also use the [Sniffybara](https://github.com/department-of-veterans-affairs/sniffybara) adapter to scan each page visited in our feature tests for 508 compliance using the AxE tool, and the VA 508 ruleset)

##Continuous Integration in Travis CI
When ever a pull request is created, it will automatically create a build on Travis CI. That build will run the `bundle exec rake` command, which runs all linters, security scans, unit tests, and feature tests for the project. All code must have a successful build in Travis CI before it can be merged into master.

#Code Review
All PR's must be reviewed by at least one other team member. If two team members paired on the code, then its fine for one of those two to act as the reviewer. It's also encouraged to get extra eyes on code that you feel a little more uncomfortable about.

**Things to check for in a code review:**
- Are we duplicating any logic that could be reused instead? This includes hand writing features that we could be using rails for.
- Every logic path of every added method should have a unit test.
- Are feature tests modified or added to account for the new functionality?
- There should be NO migrations that remove or rename columns alongside any additional code. These migrations can cause major bugs, and should be part of their own PR.

##Integration Testing and Deployment
Whenever a PR is merged into master, an automated Jenkins job will deploy to all non-production environments.

Before stories can be launched (their feature flag is removed). A QA or designer must validate the story's completion in a non-production environment. See our [Story Column descriptions](/docs/process.md) for more details. 

Before any deployment to production, a "happy path" smoke test must be performed for each major feature to make sure the integrations with our dependencies are functioning correctly. Currently, this smoke test will be performed manually, however, we will be working on automating it. Manual & automated smoke tests will be recorded in the [appeals-qa](https://github.com/department-of-veterans-affairs/appeals-qa) repository.

Deployments must be performed regularly in order to make sure production and master do not diverge too quickly. We will deploy 5pm EST on Tuesdays and Thursdays. Urgent ad-hoc deployments are also OK.

##Monitoring and Rollbacks
Even with a strong battery of automated and manual testing, bugs still happen. We use Sentry, Caseflow Stats Page, Cloud Watch, Pager Duty, and Google Analytics to make sure production is running smoothly.

If it's discovered that there is a major issue introduced by a deployment, we will immediately revert. Since we only allow backwards-compatible migrations (unless they are heavily veted, and part of their own deployment, see "Code Reviews"), this should be smooth and painless. The bug should then be diagnosed and fixed as quickly as possible in UAT. All deployments will be halted until the issue is resolved. If the issue can't be resolved within two days, we will revert the offending PR.
