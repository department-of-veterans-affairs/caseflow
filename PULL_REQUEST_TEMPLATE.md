Resolves #{github issue number}

### Description
Please explain the changes you made here.

### Acceptance Criteria
- [ ] Code compiles correctly

### Testing Plan
1. Go to ...

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

* [ ] Timestamps (created_at, updated_at) for new tables
* [ ] Column comments updated
* [ ] Query profiling performed (eyeball Rails log, check bullet and fasterer output)
* [ ] Appropriate indexes added (especially for foreign keys, polymorphic columns, and unique constraints)
* [ ] DB schema docs updated with `make docs`
* [ ] #appeals-schema notified with summary and link to this PR
