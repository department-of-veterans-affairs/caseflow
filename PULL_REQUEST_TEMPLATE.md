Resolves [Jira Issue Title](https://jira.devops.va.gov/browse/JIRA-12345)

# Description
Please explain the changes you made here.

## Acceptance Criteria
- [ ] Code compiles correctly

## Testing Plan
1. Go to #{jira issue link} or list them below

- [ ] For feature branches merging into master: Was this deployed to UAT?

# Frontend
## User Facing Changes
 - [ ] Screenshots of UI changes added to PR & Original Issue

 BEFORE|AFTER
 ---|---

## Storybook Story
*For Frontend (Presentation) Components*
* [ ] Add a [Storybook](https://github.com/department-of-veterans-affairs/caseflow/wiki/Documenting-React-Components-with-Storybook) file alongside the component file (e.g. create `MyComponent.stories.js` alongside `MyComponent.jsx`)
* [ ] Give it a title that reflects the component's location within the overall Caseflow hierarchy
* [ ] Write a separate story (within the same file) for each discrete variation of the component

# Backend
## Database Changes
*Only for Schema Changes*

* [ ] Add typical timestamps (`created_at`, `updated_at`) for new tables
* [ ] Update column comments; include a "PII" prefix to indicate definite or potential [PII data content](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/caseflow-team/0-how-we-work/pii-handbook.md#what-is-pii)
* [ ] Have your migration classes inherit from `Caseflow::Migration`, especially when adding indexes (use `add_safe_index`) (see [Writing DB migrations](https://github.com/department-of-veterans-affairs/caseflow/wiki/Writing-DB-migrations))
* [ ] Verify that `migrate:rollback` works as desired ([`change` supported functions](https://edgeguides.rubyonrails.org/active_record_migrations.html#using-the-change-method))
* [ ] Perform query profiling (eyeball Rails log, check bullet and fasterer output)
* [ ] For queries using raw sql was an explain plan run by System Team
* [ ] Add appropriate indexes (especially for foreign keys, polymorphic columns, unique constraints, and Rails scopes)
* [ ] Run `make check-fks`; add any missing foreign keys or add to `config/initializers/immigrant.rb` (see [Record associations and Foreign Keys](https://github.com/department-of-veterans-affairs/caseflow/wiki/Record-associations-and-Foreign-Keys))
* [ ] Add `belongs_to` for associations to enable the [schema diagrams](https://department-of-veterans-affairs.github.io/caseflow/task_trees/schema/schema_diagrams) to be automatically updated
* [ ] Document any non-obvious semantics or logic useful for interpreting database data at [Caseflow Data Model and Dictionary](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Data-Model-and-Dictionary)

## Integrations: Adding endpoints for external APIs
* [ ] Check that Caseflow's external API code for the endpoint matches the code in the relevant integration repo
  * [ ] Request: Service name, method name, input field names
  * [ ] Response: Check expected data structure
  * [ ] Check that calls are wrapped in MetricService record block
* [ ] Check that all configuration is coming from ENV variables
  * [ ] Listed all new ENV variables in description
  * [ ] Worked with or notified System Team that new ENV variables need to be set
* [ ] Update Fakes
* [ ] For feature branches: Was this tested in Caseflow UAT

# Best practices
## Code Documentation Updates
- [ ] Add or update code comments at the top of the class, module, and/or component.

## Tests
### Test Coverage
Did you include any test coverage for your code? Check below:
- [ ] RSpec
- [ ] Jest
- [ ] Other

### Code Climate
Your code does not add any new code climate offenses? If so why?
- [ ] No new code climate issues added

## Monitoring, Logging, Auditing, Error, and Exception Handling Checklist

### Monitoring
- [ ] Are performance metrics (e.g., response time, throughput) being tracked?
- [ ] Are key application components monitored (e.g., database, cache, queues)?
- [ ] Is there a system in place for setting up alerts based on performance thresholds?

### Logging
- [ ] Are logs being produced at appropriate log levels (debug, info, warn, error, fatal)?
- [ ] Are logs structured (e.g., using log tags) for easier querying and analysis?
- [ ] Are sensitive data (e.g., passwords, tokens) redacted or omitted from logs?
- [ ] Is log retention and rotation configured correctly?
- [ ] Are logs being forwarded to a centralized logging system if needed?

### Auditing
- [ ] Are user actions being logged for audit purposes?
- [ ] Are changes to critical data being tracked ?
- [ ] Are logs being securely stored and protected from tampering or exposing protected data?

### Error Handling
- [ ] Are errors being caught and handled gracefully?
- [ ] Are appropriate error messages being displayed to users?
- [ ] Are critical errors being reported to an error tracking system (e.g., Sentry, ELK)?
- [ ] Are unhandled exceptions being caught at the application level ?

### Exception Handling
- [ ] Are custom exceptions defined and used where appropriate?
- [ ] Is exception handling consistent throughout the codebase?
- [ ] Are exceptions logged with relevant context and stack trace information?
- [ ] Are exceptions being grouped and categorized for easier analysis and resolution?

