#Caseflow Development Process
These columns in the [Caseflow waffle board](https://waffle.io/department-of-veterans-affairs/caseflow) describe the states and life cycle of a story. This is a work-in-progress and will continue to evolve to fit the needs of the team. We will use **Retrospectives** at the end of each sprint to facilitate this.

##Inbox
Landing place for all new issues. We should look at and move these issues to the appropriate column ASAP.

##Backlog
Place for any issue that we aren't planning on designing or working on in the near future. We will occasionally comb the backlog for issues to be pulled into "Triage".

##Triage
Place for stories that are prioritized to be added to "Ready for Dev" but don't quite have enough definition. This column was added because "Backlog" can become very unwieldy.

##Ready for Development
Any story in this column should be well formed enough to be picked up and worked on by a developer.
They will also always be in priority order (by-project).
At the beginning of a sprint, in **Sprint Planning**, sprint teams will review these stories one by one together to gain a shared understanding of each story and to decide what they can commit to completing.
Stories that teams commit to completing in sprint planning will be moved to the current sprint column. 

For the most part, stories will be added to this column by breaking apart large designs managed in Appeals PM.
This is done in **Story Time**.
Additionally bugs and technical stories will be pulled into this column and prioritized from the backlog during story time, or ad hoc as necessary.

##Tech 💪 Backlog
Stories labeled `tech-improvement` that are ready for development. Unlike the "Ready for Development" column, these stories are just roughly prioritized, and an attempt should be made to work on stories here 10-15% of the sprint.

##Current Sprint
Development work that sprint teams have committed to for the current sprint.
We should aim to have this column completely cleaned out by the end of the sprint.

##In Progress
When a developer has begun working on a story, they move it into In Progress. Additionally, any open PRs are placed here by default.

##In Validation
When all code related to completing an issue has been merged into master.
That code is automatically deployed to UAT and Dev.
A QA and/or designer should validate that the application functionality matches the acceptance criteria, it's 508 compliant, it matches the design (if supplied). Then, it can be moved to "Done".

Note: Developers should provide any instructions needed to test this feature in development, such as fake data or URL paths.

#Additional Notes
- Labels should be added to stories as appropriate. See the [label definitions document](/docs/labels.md) for more details.
