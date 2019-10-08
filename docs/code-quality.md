# Code Quality

The Caseflow application has evolved rapidly since 2016. We are continually striving to
improve the quality and consistency of the code in order to reduce bugs and improve
our ability to deliver features. Quality code is readable code.

## Tools

We use a variety of automated tools to help us in this process.

### Rubocop

The `.rubocop.yml` file defines the [Rubocop](https://github.com/rubocop-hq/rubocop) rules we adhere to.
When we want to define exceptions to those rules we place special comments in the code.

### Reek

[Reek](https://github.com/troessner/reek) is a "code smell detector" that helps us identify patterns
in our code we would like to avoid. The `.reek.yml` file allows us to define which rules
and exceptions we allow.

## Process

We automatically run Rubocop and Reek via the [Code Climate](https://codeclimate.com/github/department-of-veterans-affairs/caseflow/) tool. Every PR is evaluated by Code Climate and must pass before being merged.

Any PR-specific exceptions to the Code Climate checks should be made as part of the PR in the `.rubocop.yml`,
`.reek.yml` or Rubocop comments. We do not use the Code Climate exception/ignore/skip functionality to
bypass checks.

If we do introduce new exceptions to the checks as part of the PR review process, we drop a link
and brief explanation in the #appeals-code-quality Slack channel in order to increase visibility of the change.

Ultimately it is up to the PR author and reviewers to determine whether the exception is allowed.

If we see patterns in exceptions being made, discussion and decisions about more permanent changes to the
rules we follow are made in the #appeals-code-quality channel.
