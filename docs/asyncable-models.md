Asyncable Models
======================

The problem: external calls to VBMS and BGS can take a long time to run, and sometimes they fail due to a variety of reasons. This caused problems for our users, who had to wait for the tasks to run and then re-do work if they failed through no fault of their own.

So we decided to audit our Intake-related models and move all our external service calls to run asynchronously, in the background. They also needed to be idempotent, so that retries would not create duplicate data.

We already have ActiveJob and the shoryuken (https://github.com/phstc/shoryuken) gem for handing cron and background tasks. It's configured to automatically retry jobs in a progressively decaying interval https://github.com/department-of-veterans-affairs/caseflow/blob/master/config/initializers/shoryuken.rb#L8

Our dilemma was that sometimes external services go down for hours, and we wanted a retry interval that stretched into days. Also, we wanted to be able to query the database to see the status of these tasks.

What we hit on was an asynchronous pattern that uses both shoryuken to run outside the web process and the database for state persistence.

https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/concerns/asyncable.rb

The `Asyncable` concern requires 4 columns be added to any ActiveRecord model:

* submitted_at
* attempted_at
* processed_at
* error

The naming is flexible -- you can override the default column names with class methods in the consuming model.

The `Asyncable` concern adds a variety of class scope methods for querying categories of tasks that run in the background.

By default, tasks run every 3 hours and will expire after 4 days.

We use those scoping methods in a cron job:
https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/jobs/sync_reviews_job.rb

to fire off shoryuken jobs:
https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/jobs/claim_review_process_job.rb

We have a TODO item for ourselves to create a UI page to view and manually retry failed tasks:
https://github.com/department-of-veterans-affairs/caseflow/issues/6944

For now, though, we're seeing tasks occasionally fail as before, but now they retry themselves hours later and succeed, without any intervention from us.

