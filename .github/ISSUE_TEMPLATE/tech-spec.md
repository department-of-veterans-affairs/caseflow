---
name: Tech Spec template
about: Template for a new tech spec
title: "[SUBJECT] Tech Spec"
labels: 'Type: Tech-Spec'
assignees: ''

---

# Tech Spec Title
**Drafter**: <!-- Your name -->  
**Discussion Meeting**: <!-- Date to discussion the spec as a team; send calendar invite! -->  

<!-- Tech specs are a lightweight format for documenting technical research and decision making. The headings below are guidelines, not rules, so modify your copy as you see fit. Especially large tech specs may require more headings and subheadings for example. Be rigorous in your research and planning, but balance that with forward progress - if something is uncertain, document that appropriately and move on if you can. Getting feedback early from team mates during tech spec writing can be helpful too.
Tech specs are considered 'done' when key stakeholders have reviewed and approved the approach. -->

## Context
<!-- Why are you creating this tech spec? 

What information helps readers understand the rest of this tech spec? 

Who are the stakeholders? -->

## Overview
<!-- A brief summary of research, findings, and recommendations. -->

### Requirements and/or Acceptance Criteria
<!-- What requirements are being addressed? What acceptance criteria should be fulfilled by the solution? -->

### Concerns
<!-- Concerns about potential solutions. Explicitly state if they should be addressed in the chosen solution. -->

## Open Questions
<!-- Sometimes we're missing information needed to fully spec work. 
What is missing? Who can answer these questions, and how might it affect the recommendation? -->

## Implementation Options
<!-- 
Consider multiple implementation paths.
What are their recommended action items?
These may change as feedback is given, but after the tech spec is approved these should be written as fully defined/pointed github issues.
Is the work sufficiently defined such that someone else could pick it up?
Is the work parallelizable?
What new API endpoints, database fields / tables / models need to be defined?
How will we safely ship this work? Are there migrations, external dependencies that need to be notified, documentation changes, etc? -->

### Implementation concerns
<!-- List implementation-specific concerns about each option. -->

## Test Plan
<!-- How do we validate this work? What types of testing is required? -->

## Rollout Plan
<!-- Is there a phased rollout? What needs to be done to mitigate rollout risks? -->

## Research Notes
<!-- Add any accrued research, links to relevant meeting notes, and sources of truth. This is also a good place to document any history to the recommended implementation - if feedback has changed the final approach, leave a note about it here -->

# Tech Spec Process

 - [ ] Tech spec drafter: Schedule time to discuss the tech spec with scrum team or whole engineering team depending on the scope of the tech spec
 - [ ] Tech spec drafter: Facilitate that discussion.
 - [ ] Other developers: Read the tech spec before arriving at the discussion.
 - [ ] Other developers: Remind the tech spec drafter if a tech spec has been produced and no meeting has been scheduled.
 - [ ] One or more solutions determined as viable paths forward
 - [ ] Tech spec drafter: Turn tech spec into next-step actionable tickets.
    - [ ] Write tickets as is necessary
    - [ ] Other developers provide more formal feedback as is necessary.
- [ ] Once the tech spec is finalized, open a PR to add it to the docs/tech-specs directory following [these instructions](https://github.com/department-of-veterans-affairs/caseflow/tree/master/docs/tech-specs/README.md)
