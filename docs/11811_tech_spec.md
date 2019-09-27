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
No parent task | Should not happen.<sup>[1](#footnote1)</sup> | Should not happen.<sup>[1](#footnote1)</sup>
Parent task assigned to `Organization` using automatic child task assignment | e.g. `BvaDispatchTask`s assigned to the `BvaDispatch` organization. | Should not happen.<sup>[2](#footnote2)</sup>
Parent task assigned to `Organization` without automatic assignment | e.g. `QualityReviewTask`s assigned to the `QualityReview` organization. | Should only happen for `JudgeTask`s.<sup>[2](#footnote2)</sup>
Parent task assigned to `User` | Should not happen.<sup>[3](#footnote3)</sup> | e.g. `AttorneyTask` child of `JudgeDecisionReviewTask`
Parent task is `RootTask` assigned to `Bva` | n/a | `JudgeAssignTask` and `JudgeDecisionReviewTask`.<sup>[2](#footnote2)</sup>

These five circumstances we expect to find tasks in when they are re-assigned suggest five approaches for handling the tasks to be re-assigned.

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

4. Handling open `JudgeAssignTask`s assigned to judges who become inactive is a little more involved. However, since those cases have not yet been distributed to attorneys, we can simply put those cases back in the pool of cases to be distributed and cancel the open `JudgeAssignTask`.

```ruby
def reassign_open_tasks_for(user)
  user.tasks.open.each do |task|
    ...

    if task.is_a?(JudgeAssignTask)
      if task.children.open.any?
        fail "#{task.type} assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} has open children tasks"
      end
      DistributionTask.create!(appeal: task.appeal, parent: task.appeal.root_task)
      task.update!(status: Constants.TASK_STATUSES.cancelled)
    end

    ...
  end
end
```

5. Handling open `JudgeDecisionReviewTask`s assigned to judges who become inactive is a more complicated still. Since each `JudgeDecisionReviewTask` will have an associated `AttorneyTask` for the decision the attorney drafted for the judge's review we can use the attorney's new judge team to determine who should review the case.

```ruby
def reassign_open_tasks_for(user)
  user.tasks.open.each do |task|
    ...

    if task.is_a?(JudgeDecisionReviewTask)
      atty_task = task.children_attorney_tasks.not_cancelled.order(:assigned_at).last
      if atty_task.nil?
        fail "#{task.type} assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} does not have any child AttorneyTasks"
      end

      new_supervising_judge = atty_task.assigned_to.organizations.find_by(type: JudgeTeam.name)&.judge
      if new_supervising_judge.nil?
        fail "#{atty_task.type} assigned to attorney User ID #{atty_task.assigned_to.id} for #{task.appeal_type} ID #{task.appeal_id} who does not belong to a JudgeTeam"
      end

      task.reassign({ assigned_to_type: User.name, assigned_to_id: new_supervising_judge.id }, nil)
    end

    ...
  end
end
```

## Complications

A naive approach of reassigning all tasks for each appeal in whatever order they are returned by the database likely runs into several complications, a few of which are mentioned below. We will certainly discover more as we test the implementation and run the code in production.

* How do we account for `TimedHoldTask`s?
    - Perhaps this logic could be incorporated into `Task.reassign` so that `TimedHoldTask`s that are children of reassigned tasks are automatically re-assigned as well?
* How do we handle a other examples where a branch of an appeal's task tree with consecutive nodes assigned to the same person?
    - Perhaps we can start by reassigning the farthest end of each task tree branch and work up the ancestors from there?

## Recommended approach

Example implementation that could be included [as a Rake task](https://github.com/department-of-veterans-affairs/caseflow/blob/master/lib/tasks/tasks.rake):

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

      if task.parent.nil?
        fail "Open task assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} has no parent task"
      elsif task.is_a?(JudgeAssignTask)
        if task.children.open.any?
          fail "#{task.type} assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} has open children tasks"
        end
        DistributionTask.create!(appeal: task.appeal, parent: task.appeal.root_task)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      elsif task.is_a?(JudgeDecisionReviewTask)
        atty_task = task.children_attorney_tasks.not_cancelled.order(:assigned_at).last
        if atty_task.nil?
          fail "#{task.type} assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} does not have any child AttorneyTasks"
        end
        new_supervising_judge = atty_task.assigned_to.organizations.find_by(type: JudgeTeam.name)&.judge
        if new_supervising_judge.nil?
          fail "#{atty_task.type} assigned to attorney User ID #{atty_task.assigned_to.id} for #{task.appeal_type} ID #{task.appeal_id} who does not belong to a JudgeTeam"
        end
        task.reassign({ assigned_to_type: User.name, assigned_to_id: new_supervising_judge.id }, nil)
      elsif task.parent.automatically_assign_org_task? && task.type == task.parent.type
        task.reassign({ assigned_to_type: User.name, assigned_to_id: task.parent.assigned_to.next_assignee }, nil)
      elsif task.parent.assigned_to.is_a?(Organization) && task.type == task.parent.type
        task.parent.update!(status: Constants.TASK_STATUSES.assigned)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      elsif task.parent.assigned_to.is_a?(User) && task.type != task.parent.type
        task.parent.update!(status: Constants.TASK_STATUSES.assigned)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      elsif task.parent.assigned_to.is_a?(Organization) && task.type != task.parent.type
        fail "Open task assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} has a parent task of a different type assigned to an organization"
      elsif task.parent.assigned_to.is_a?(User) && task.type == task.parent.type
        fail "Open task assigned to User #{user.id} for #{task.appeal_type} ID #{task.appeal_id} has a parent task of the same type assigned to a user"
      end
      
      # Update the instructions with a note detailing what we've done.
      task.update!(instructions: [task.instructions, "Re-assigning open task for inactive user"].flatten)
    end
  end
end
```

## Additional considerations

Additionally, it may be worthwhile to alert folks via email (or some means other than simply task re-assignment which relies on somebody checking a particular queue). Electing to send an email in addition to or in place of re-assigning a task does not change this implementation in any meaningful way since we will still need to identify the recipient of such an email (a `Organization`'s administrator, for instance) and will rely on the task tree to identify that recipient.

## First targets

We have already [identified two inactive users](https://github.com/department-of-veterans-affairs/caseflow/issues/12173) who will go through this process and a quick survey of their open tasks below suggests that the approach above will properly handle each of those situations.

```sql
select count(child_task.*)
, child_task.type
, parent_task.type
, parent_task.assigned_to_type
, users.css_id
from tasks child_task
join tasks parent_task
  on parent_task.id = child_task.parent_id 
join users
  on users.id = child_task.assigned_to_id
  and child_task.assigned_to_type = 'User'
where child_task.status not in ('cancelled', 'completed')
  and child_task.assigned_to_type = 'User'
  and users.css_id in ('VSCLHALL', 'ADJEWILH')
group by 2, 3, 4, 5
order by 5, 1 desc, 2, 3, 4;

 count |                       type                       |                       type                       | assigned_to_type |  css_id  
-------+--------------------------------------------------+--------------------------------------------------+------------------+----------
   103 | OtherColocatedTask                               | OtherColocatedTask                               | Organization     | ADJEWILH
    78 | ExtensionColocatedTask                           | ExtensionColocatedTask                           | Organization     | ADJEWILH
    55 | HearingClarificationColocatedTask                | HearingClarificationColocatedTask                | Organization     | ADJEWILH
    29 | StayedAppealColocatedTask                        | StayedAppealColocatedTask                        | Organization     | ADJEWILH
    27 | IhpColocatedTask                                 | IhpColocatedTask                                 | Organization     | ADJEWILH
    24 | PoaClarificationColocatedTask                    | PoaClarificationColocatedTask                    | Organization     | ADJEWILH
    16 | AojColocatedTask                                 | AojColocatedTask                                 | Organization     | ADJEWILH
    14 | EvidenceOrArgumentMailTask                       | EvidenceOrArgumentMailTask                       | Organization     | ADJEWILH
     9 | MissingRecordsColocatedTask                      | MissingRecordsColocatedTask                      | Organization     | ADJEWILH
     8 | RetiredVljColocatedTask                          | RetiredVljColocatedTask                          | Organization     | ADJEWILH
     8 | TimedHoldTask                                    | ExtensionColocatedTask                           | User             | ADJEWILH
     4 | AddressVerificationColocatedTask                 | AddressVerificationColocatedTask                 | Organization     | ADJEWILH
     2 | NewRepArgumentsColocatedTask                     | NewRepArgumentsColocatedTask                     | Organization     | ADJEWILH
     2 | TimedHoldTask                                    | OtherColocatedTask                               | User             | ADJEWILH
     1 | ArnesonColocatedTask                             | ArnesonColocatedTask                             | Organization     | ADJEWILH
     1 | PendingScanningVbmsColocatedTask                 | PendingScanningVbmsColocatedTask                 | Organization     | ADJEWILH
     1 | PreRoutingFoiaColocatedTask                      | PreRoutingFoiaColocatedTask                      | Organization     | ADJEWILH
     1 | PreRoutingMissingHearingTranscriptsColocatedTask | PreRoutingMissingHearingTranscriptsColocatedTask | Organization     | ADJEWILH
    75 | OtherColocatedTask                               | OtherColocatedTask                               | Organization     | VSCLHALL
    46 | ExtensionColocatedTask                           | ExtensionColocatedTask                           | Organization     | VSCLHALL
    30 | HearingClarificationColocatedTask                | HearingClarificationColocatedTask                | Organization     | VSCLHALL
    22 | IhpColocatedTask                                 | IhpColocatedTask                                 | Organization     | VSCLHALL
    15 | EvidenceOrArgumentMailTask                       | EvidenceOrArgumentMailTask                       | Organization     | VSCLHALL
    11 | StayedAppealColocatedTask                        | StayedAppealColocatedTask                        | Organization     | VSCLHALL
    10 | PoaClarificationColocatedTask                    | PoaClarificationColocatedTask                    | Organization     | VSCLHALL
     9 | TimedHoldTask                                    | ExtensionColocatedTask                           | User             | VSCLHALL
     8 | AddressVerificationColocatedTask                 | AddressVerificationColocatedTask                 | Organization     | VSCLHALL
     6 | RetiredVljColocatedTask                          | RetiredVljColocatedTask                          | Organization     | VSCLHALL
     3 | AojColocatedTask                                 | AojColocatedTask                                 | Organization     | VSCLHALL
     3 | MissingRecordsColocatedTask                      | MissingRecordsColocatedTask                      | Organization     | VSCLHALL
     2 | ArnesonColocatedTask                             | ArnesonColocatedTask                             | Organization     | VSCLHALL
     2 | ExtensionRequestMailTask                         | ExtensionRequestMailTask                         | Organization     | VSCLHALL
     2 | PendingScanningVbmsColocatedTask                 | PendingScanningVbmsColocatedTask                 | Organization     | VSCLHALL
     2 | ScheduleHearingColocatedTask                     | ScheduleHearingColocatedTask                     | Organization     | VSCLHALL
     1 | PowerOfAttorneyRelatedMailTask                   | PowerOfAttorneyRelatedMailTask                   | Organization     | VSCLHALL
     1 | TimedHoldTask                                    | OtherColocatedTask                               | User             | VSCLHALL
     1 | TimedHoldTask                                    | StayedAppealColocatedTask                        | User             | VSCLHALL
(37 rows)
```

## Footnotes

<a name="footnote1">1</a>: As of 27 Sep 2019 all open tasks assigned to `User`s have parent tasks.
```sql
select count(*)
, type
from tasks
where status not in ('cancelled', 'completed')
  and assigned_to_type = 'User'
  and parent_id is null
group by 2;

 count | type 
-------+------
(0 rows)
```

<a name="footnote2">2</a>: As of 27 Sep 2019 all open tasks assigned to `User`s that have parent tasks assigned to `Organization`s have the same task type as their parent task with the exception of `JudgeTask`.
```sql
select count(child_task.*)
, child_task.type
, parent_task.type
from tasks child_task
join tasks parent_task
  on parent_task.id = child_task.parent_id 
  and parent_task.type <> child_task.type
where child_task.status not in ('cancelled', 'completed')
  and child_task.assigned_to_type = 'User'
  and parent_task.assigned_to_type = 'Organization'
group by 2, 3;

 count |          type           |   type   
-------+-------------------------+----------
  1118 | JudgeDecisionReviewTask | RootTask
   538 | JudgeAssignTask         | RootTask
(2 rows)
```

<a name="footnote3">3</a>: As of 27 Sep 2019 all open tasks assigned to `User`s that have parent tasks assigned to `User`s have a different task type than their parent task.
```sql
select count(child_task.*)
, child_task.type
, parent_task.type
from tasks child_task
join tasks parent_task
  on parent_task.id = child_task.parent_id 
  and parent_task.type = child_task.type
where child_task.status not in ('cancelled', 'completed')
  and child_task.assigned_to_type = 'User'
  and parent_task.assigned_to_type = 'User'
group by 2, 3;

 count | type | type 
-------+------+------
(0 rows)
```
