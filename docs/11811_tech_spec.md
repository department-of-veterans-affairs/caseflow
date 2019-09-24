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

## Options

When sketching out options for how to handle open tasks assigned users who become inactive or leave organizations we will consider only the case where a user is inactive because the approach does not depend on whether the user is currently a member of any organization at all.

 . | Child and parent task have same type | Child and parent task have different types
 --- | --- | ---
Parent task assigned to `Organization` using automatic child task assignment | e.g. `BvaDispatchTask`s assigned to the `BvaDispatch` organization. | Should not happen.
Parent task assigned to `Organization` without automatic assignment | e.g. `QualityReviewTask`s assigned to the `QualityReview` organization. | Should not happen.
Parent task assigned to `User` | Should not happen. | e.g. `AttorneyTask` child of `JudgeDecisionReviewTask`

The three circumstances we expect to find tasks in when they are re-assigned suggest three approaches for handling the tasks to be re-assigned.

1. When the child task to be re-assigned and parent task assigned to an `Organization` using automatic child task assignment have the same type we can automatically re-assign the task to the next person who would be automatically selected by child task assignment. A sketch of this approach would look something like the following:

```ruby
def reassign_open_tasks_for(user)
  user.tasks.open.each do |task|
    ...

    if task.parent.automatically_assign_org_task?
      task.reassign({ assigned_to_type: User.name, assigned_to_id: task.parent.assigned_to.next_assignee }, nil)
    end

    ...
  end
end
```

2. When the child task to be re-assigned and parent task assigned to an `Organization` without automatic assignment have the same type we can cancel the child task and change the task status of the parent task to `assigned`. Since the organization is not using automatic assignment we assume the organization's queue is monitored and the task becoming active again in that queue will be noticed by a member of that organization. Sketching that approach we arrive at something like:

```ruby
def reassign_open_tasks_for(user)
  user.tasks.open.each do |task|
    ...

    if task.parent.assigned_to.is_a?(Organization)
      task.parent.update!(status: Constants.TASK_STATUSES.assigned)
      task.update!(status: Constants.TASK_STATUSES.cancelled)
    end

    ...
  end
end
```

3. For those same reasons we can re-activate parent tasks assigned to `User`s.

For the circumstances that we do not expect to find tasks to be-reassigned in, we can throw an exception and investigate the conditions that allowed the application to reach that state should we throw that exception.

## Complications

A naive approach of reassigning all tasks for each appeal in whatever order they are returned by the database likely runs into several complications, a few of which are mentioned below. We will certainly discover more as we test the implementation and run the code in production.

* How do we account for `TimedHoldTask`s?
    - Perhaps this logic could be incorporated into `Task.reassign` so that `TimedHoldTask`s that are children of reassigned tasks are automatically re-assigned as well?
* How do we handle a other examples where a branch of an appeal's task tree with consecutive nodes assigned to the same person?
    - Perhaps we can start by reassigning the farthest end of each task tree branch and work up the ancestors from there?

## Recommended approach

```ruby
def reassign_open_tasks_for(user)
  ActiveRecord::Base.multi_transaction do
    # Group by appeal in order to avoid the complications described above for the time being.
    user.tasks.open.group(:appeal_id, :appeal_type).count.each do |appeal_info, count|
      if count > 1
        # Alternatively just skip this appeal, collect appeals in this state, and send message after reassigning
        # tasks for appeals with only 1 open task.
        fail "Requires manual intervention because #{appeal_info[1]} ID #{appeal_info[0]} has more than 1 open task"
      end

      task = user.tasks.open.find_by(appeal_id: appeal_info[0], appeal_type: appeal_info[1])

      if task.parent.automatically_assign_org_task? && task.type == task.parent.type
        task.reassign({ assigned_to_type: User.name, assigned_to_id: task.parent.assigned_to.next_assignee }, nil)
      elsif task.parent.assigned_to.is_a?(Organization) && task.type == task.parent.type
        task.parent.update!(status: Constants.TASK_STATUSES.assigned)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      elsif task.parent.assigned_to.is_a?(User) && task.type != task.parent.type
        task.parent.update!(status: Constants.TASK_STATUSES.assigned)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      elsif task.parent.assigned_to.is_a?(Organization) && task.type != task.parent.type
        fail "Open task assigned to User #{user.id} for #{appeal_info[1]} ID #{appeal_info[0]} has a parent task of a different type assigned to an organization"
      elsif task.parent.assigned_to.is_a?(User) && task.type == task.parent.type
        fail "Open task assigned to User #{user.id} for #{appeal_info[1]} ID #{appeal_info[0]} has a parent task of the same type assigned to a user"
      end
      
      # Update the instructions with a note detailing what we've done.
      task.update!(instructions: [task.instructions, "Re-assigning open task for inactive user"].flatten)
    end
  end
end
```

## Additional considerations

Additionally, it may be worthwhile to alert folks via email (or some means other than simply task re-assignment which relies on somebody checking a particular queue). Electing to send an email in addition to or in place of re-assigning a task does not change this implementation in any meaningful way since we will still need to identify the recipient of such an email (a `Organization`'s administrator, for instance) and will rely on the task tree to identify that recipient.
