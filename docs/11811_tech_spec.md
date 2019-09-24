# Handle tasks assigned users who become inactive or leave organizations

This document outlines the technical implementation of several approaches for handling open tasks assigned to users who become inactive or leave organizations so that appeals can continue continue to progress through the appeals process when the person responsible for the next step is no longer capable of taking that next step.

## Non-goals

This does not attempt to do any of the following:
* Define what it means for a user to "become inactive"
    - `User.status` changes to something other than `active` perhaps?
* Determine how a user is deactivated
    - Could be a manual step on the team administration page
    - Could be a job that we run to check when a user last logged in at, and deactivate them if they haven't logged in in a long time (might be a good job to set up)
    - Maybe the user could mark themselves as inactive?
* Prescribe what happens when the last active member of an `Organization` becomes inactive
* Determine which approach to take for each type of task and de-activiation scenario
    - Expect that determination to be made by the product team in consultation with Board employees, as described in [this Slack post by LP](https://dsva.slack.com/files/T03FECE8V/FN5GLN4ES?origin_team=T03FECE8V) (reproduced as a standalone document in this PR)

## Assumptions

* This document assumes that this process begins after the application has identified the inactive user (or user who just left an organization) whose open tasks we want to handle.
* The existing reassign() function will satisfy the mechanical problem of reassigning tasks even when they are not the terminal node in a branch of the task tree. That is, if a user becomes inactive, tasks that are children of tasks assigned to the newly-inactive user will still be available for action.
* The application does not care if the task's assignee is no longer a member of the organizationally-assigned parent task is assigned when we are re-assigning their tasks. That is, if we are re-assigning the inactive user Billie's `AojColocatedTask` which has a parent `AojColocatedTask` assigned to the `Colocated` organization, we do not care if Billie is still a member of the `Colocated` organization or not.

## Approaches

When sketching out options for how to handle open tasks assigned users who become inactive or leave organizations we will start by only considering the case where a user is inactive, and address how each approach would differ later in this document. The various scenarious we need to consider can be described by the intersection of parent task assignee and child/parent task type agreement.

 . | Child and parent task have same type | Child and parent task have different types
 --- | --- | ---
Parent task assigned to *Organization* using automatic child task assignment | e.g. `BvaDispatchTask`s assigned to the `BvaDispatch` organization. | Should not happen.
Parent task assigned to *Organization* without automatic assignment | e.g. `QualityReviewTask`s assigned to the `QualityReview` organization. | Should not happen.
Parent task assigned to *User* | Should not happen. | e.g. `AttorneyTask` child of `JudgeDecisionReviewTask`

... 

## Complications

* How do we account for `TimedHoldTask`s?
* How do we handle a other examples where a branch of an appeal's task tree with consecutive nodes assigned to the same person?
    - Perhaps we can start by reassigning the farthest end of each task tree branch and work up the ancestors from there?

## Differences when users left organizations instead of becoming inactive

...

--- --- --- --- ---

Child of
* Organizationally-assigned task of same type that uses automatic assignment
* Organizationally-assigned task of same type that does not use automatic assignment
* Organizationally-assigned task of different type
* Individually-assigned task of same type
* Individually-assigned task of different type

Options:
* Require manual intervention. Send an email to somebody who can re-assign the task (Board tema admin or supervising judge) to let them know that a user is inactive. Ask them to manually re-assign the task.
  - Are there any tasks assigned to folks who are not on any teams?
    * Roughly 700 (https://caseflow-looker.va.gov/sql/fzsymkwk9tcwdp):
      select *
      from tasks
      where assigned_to_type = 'User'
        and tasks.status not in ('cancelled', 'completed')
        and assigned_to_id in (
          select distinct(users.id)
          from users
          join tasks
            on tasks.assigned_to_id = users.id
            and tasks.assigned_to_type = 'User'
            and tasks.status not in ('cancelled', 'completed')
          where users.id not in (
            select distinct(user_id)
            from organizations_users
          )
        );
    * Lots of different task types have this problem (https://caseflow-looker.va.gov/sql/xp2syd99sj8zfb)
      select count(*)
      , type
      from tasks
      where assigned_to_type = 'User'
        and tasks.status not in ('cancelled', 'completed')
        and assigned_to_id in (
          select distinct(users.id)
          from users
          join tasks
            on tasks.assigned_to_id = users.id
            and tasks.assigned_to_type = 'User'
            and tasks.status not in ('cancelled', 'completed')
          where users.id not in (
            select distinct(user_id)
            from organizations_users
          )
        )
      group by 2
      order by 1 desc;
  * A lot of ColocatedTasks that are assigned to folks not on any teams... why are this still assigned to folks?
  * Who are assigned all of these tasks and what are they? (https://caseflow-looker.va.gov/sql/z7zjs9vzskz9mt). Mostly ColocatedTasks.

* Re-assign the task to the next person in the automatic assignment.
* Cancel the task and let the assignee of the parent task deal with the consequences (re-assign as needed). May need to explicitly activate the parent task before cancelling the child task.

Rollout plan:
* Create alert to let us know when an inactive user has open tasks assigned to them.
* Create batch reassignment functionality using Task.reassign() to reassign all tasks assigned to a given person (do we have an already existing rake task that does this?)
