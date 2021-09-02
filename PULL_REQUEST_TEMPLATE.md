Resolves #{github issue number}

### Description
Please explain the changes you made here.

### Acceptance Criteria
- [ ] Code compiles correctly

### Testing Plan
1. Go to ...

- [ ] For higher-risk changes: [Deploy the custom branch to UAT to test](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/Applications---Deploy-Custom-Branch-to-UAT)

### User Facing Changes
 - [ ] Screenshots of UI changes added to PR & Original Issue

 BEFORE|AFTER
 ---|---

### Code Documentation Updates
- [ ] Add or update code comments at the top of the class, module, and/or component.

### Storybook Story
*For Frontend (Presentationa) Components*
* [ ] Add a [Storybook](https://github.com/department-of-veterans-affairs/caseflow/wiki/Documenting-React-Components-with-Storybook) file alongside the component file (e.g. create `MyComponent.stories.js` alongside `MyComponent.jsx`)
* [ ] Give it a title that reflects the component's location within the overall Caseflow hierarchy
* [ ] Write a separate story (within the same file) for each discrete variation of the component

### Database Changes
*Only for Schema Changes*

* [ ] Add typical timestamps (`created_at`, `updated_at`) for new tables
* [ ] Update column comments; include a "PII" prefix to indicate definite or potential [PII data content](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/caseflow-team/0-how-we-work/pii-handbook.md#what-is-pii)
* [ ] Have your migration classes inherit from `Caseflow::Migration`, especially when adding indexes (use `add_safe_index`)
* [ ] Verify that `migrate:rollback` works as desired ([`change` supported functions](https://edgeguides.rubyonrails.org/active_record_migrations.html#using-the-change-method))
* [ ] Perform query profiling (eyeball Rails log, check bullet and fasterer output)
* [ ] Add appropriate indexes (especially for foreign keys, polymorphic columns, unique constraints, and Rails scopes)
* [ ] Run `make check-fks`; add any missing foreign keys or add to `config/initializers/immigrant.rb`
* [ ] Post this PR in #appeals-schema with a summary
* [ ] Document any non-obvious semantics or logic useful for interpreting database data at [Caseflow Data Model and Dictionary](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Data-Model-and-Dictionary)

### Integrations: Adding endpoints for external APIs
* [ ] Check that Caseflow's external API code for the endpoint matches the code in the relevant integration repo
  * [ ] Request: Service name, method name, input field names
  * [ ] Response: Check expected data structure
* [ ] Update Fakes
* [ ] Integrations impacting functionality are tested in Caseflow UAT
