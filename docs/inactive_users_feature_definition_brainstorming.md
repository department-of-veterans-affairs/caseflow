## Problems to solve

1. when users leave the Board, mark them inactive 
2. ensure their active tasks do not get lost, and therefore are reassigned
    a. Note: we think that all organization admins (as in, they are marked admins in Caseflow) can reassign individuals on their teams' tasks. See to do's to check.

Hint: BVA prob cares the most about judges and attorneys, but this applies to administrative users too (e.g. VLJ Support Staff). 

## Proposed solutions

### Problem #1 options

In Caseflow team management page (`organizations/bva/users` i think), allow users to search for a user and mark them inactive

* Unknown: Who get's to mark users active/inactive?
    - LP answer: Any user BVA decides to add to the Bva organization, which i think is the only one that currently allows users to access and use the Caseflow team management page

### Problem #2 options 

When a user is marked inactive:

1. their individual tasks are automatically cancelled, and the parent task is `assigned` to their organization. Organization admins can then manually reassign the tasks to another individual (with one exclusion, below)
    * e.g. AttorneyTask --> JudgeAssignTask
        - Unknown: what happens to the JudgeDecisionReviewTask?
            * LP answer: We'll have to ask BVA about this. i think it'll either be (1) goes to a DVC, so a DVC staff assistant can reassign or (2) goes to a Supervisory Senior Counsel to reassign (less likely)
    * e.g. individual ColocatedTask --> organization ColocatedTask
2. if the individual's tasks are on hold (?) (i.e. there are other tasks being worked below it)
    * keep them on hold, and assign to another individual
        - Unknown: Is why this behavior happens clear to the user? Should we just handle all tasks this way?
            * LP answer: Do you mean - handle all tasks to keep the same status that they had before? 
3. if the organization does round robin automatic assignment, follow that same pattern and automatically reassign?

## To dos:

Confirm that all organization admins (as in, they are marked admins in Caseflow) can reassign individuals on their teams' tasks. We know that VLJ Support Staff can currently do this.