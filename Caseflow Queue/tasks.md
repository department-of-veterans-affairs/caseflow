---
title: Tasks
parent: Caseflow Queue
nav_order: 3
___

## What are tasks?
See all Caseflow tasks' source code [here](https://github.com/department-of-veterans-affairs/caseflow/tree/master/app/models/tasks).

Tasks are how Caseflow records who has responsibility for taking action on an appeal. Tasks contain three essential pieces of information:
1. **Appeal**. Which appeal requires this action.
2. **Assignee**. Who is supposed to take the action. The assignee can be a person, a team of people, or an abstract organization used as a placeholder for some automated action that will be taken on the appeal.
3. **Type**. The type of task implies the action that is supposed to be taken.

![image](/caseflow/assets/images/currently-active-tasks.png)

* Each appeal is associated with a root task. All required tasks for the appeal will be children of this root task.
* Actions or task state change can cause new tasks to be associated with the root task or its descendant tasks.
  * Tasks determine what actions are available to a role.
  * A task's state is affected by actions taken by a user.
* Many tasks are first assigned to an `Organization`. When the _admin_ for the organization (e.g., judge, coordinator) assigns a case to an individual user, a child task (or subtask) is created and assigned to a user within that organization. The task and child task have the same type but different `assigned_to_type`.
  * When the child task is created and assigned, the parent task's state is `on_hold`.
  * When the child task's state is complete, a hook causes the parent task's state to be complete. 
  * When the child task's state is cancelled, a hook causes the parent task's state to be cancelled. 
  * Task Types that do not follow the Parent Org - Child User structure are all Judge Tasks, all Attorney Tasks, and the root task. 
    * Judge & Attorney have a similar parent/child structure, but do not mimic the behavior. 
    * This distinction is a historic artifact, rather than a deliberate choice, as those Judge & Attorney task types predate Organizations.

### Task status
  * Possible task status values (see `task.rb: enum status`): `assigned`, `in_progress`, `on_hold`, `completed`, `cancelled`. 
  * A task is `closed` if it is `completed` or `cancelled` (see `Task.closed_statuses`). 
  * `task.open?` is implemented as `!self.class.closed_statuses.include?(status)`.
  * A task is `active` (`task.active?`) if it is `assigned` or `in_progress` (see `Task.active_statuses`). 
  * Note that `Task.open_statuses` is implemented as `active_statuses.concat([Constants.TASK_STATUSES.on_hold])`, which corresponds with `task.open?` as long as no other status values are added.
  * When a status is "active" we expect properties of the task to change. When a task is not "active" we expect that properties of the task will not change.

### Cancellation reason
There are many reasons why a task might be `cancelled`. `cancellation_reason` provides a means to identify a reason for a task's most recent `cancelled` status. Usually a `cancelled` status is a final state for a task, so we wouldn't expect it to change again. The `cancellation_reason` can be cleared for a task if the task ever gets uncancelled, and a new reason can be added, should it be cancelled for a different reason. Supplemental information from users for `cancellation_reason` can be stored in `instructions`. Possible values for `cancellation_reason` are detailed here (see also `task.rb: enum cancellation_reason`):

|`cancellation_reason` value|Description|
|---------------------------|-----------|
|`poa_change`|IHP tasks are cancelled when there is a change of POA for an appeal. The IHP task for the original POA gets cancelled and a new IHP task is opened for the new POA.|

### How do tasks map to the appeals process?
* For further description, see [this slide deck](https://docs.google.com/presentation/d/1Cc84GH7giWHTNxUe3zixH7O-QT77STlptYfud9X8P1Y).
* Also check out this generated [Task Tree documentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/README.md)

### Task timestamps
Tasks all have 6 timestamps that record when certain events happen
1. `created_at`: When the `ActiveRecord` was created (done automatically by rails)
1. `updated_at`: When any field of the `ActiveRecord` was last updated (done automatically by rails)
1. `assigned_at`: When the `ActiveRecord` [is created](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L27), this is set to the creation datetime or what `assigned_at` attribute is [passed to the task](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L626) upon creation. It is also set when a task's `status` is [updated](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L644) to "[assigned](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L631)"
1. `started_at`: When a task's `status` is [updated](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L644) to "[in_progress](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L632)"
1. `placed_on_hold_at`: When a task's `status` is [updated](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L644) to "[on_hold](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L633)"
1. `closed_at`: When a task's `status` is [updated](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L644) to "[completed](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L634)" or "[cancelled](https://github.com/department-of-veterans-affairs/caseflow/blob/9b73d5ff8aa6a65be9a529b258bde91caa65de82/app/models/task.rb#L635)"

## What are task actions?
Task actions are the options that are presented in a dropdown menu on the case details page of an individual appeal. Each task has a set of actions available to be taken on it given the state of the appeal, type of task, and relationship of the current user to the appeal. Task actions do only one thing: redirect the current user to a different URL when clicked. The resulting page may be a modal or workflow where additional information is gathered to be sent in a subsequent request to the server.

[Task actions enumerated](https://airtable.com/shr17sBDY41hIlDcW/tbldCBfTWF7PfRggp/viwajGkhg8fJNqTmf?blocks=hide)

## How do tasks and organizations interact?
For a more complete look into how tasks and organizations interact, please view this [video recording of a presentation on the subject](https://zoom.us/recording/play/DheNbQYEm5Bwy3hE5sBdQ0a1Xcl44Gs573fp72-UoHNnOvAEGLQDFKcGUZpwkKN_?continueMode=true&startTime=1556124159000&autoplay=true).

## How do I recover if the task tree is in a bad state?
When the task tree cannot be restored to the correct state by actions available to Caseflow users (like cancelling a task), the Caseflow application development team can manually correct the state of the task tree. For specific examples of these occasions please visit [the dedicated wiki page](https://github.com/department-of-veterans-affairs/caseflow/wiki/Fixing-task-trees).

## What are Timed Tasks?
Tasks indicate that an action needs to be performed by somebody or some automated process. In addition to tasks that indicate some action needs to be taken by a person or some other active system, sometimes an appeal just needs to wait for some time to pass, so we created the [timed task mechanism](https://github.com/department-of-veterans-affairs/caseflow/wiki/Timed-Tasks) as a way to satisfy that need.

## What are Engineering Tasks?

An `EngineeringTask` is used to keep Caseflow users aware of engineering work (including long-term Bat Team work) on an appeal, reduce false positives when checking for stuck appeals, and enable more accurate time-keeping when reporting on Caseflow users' time spent on an appeal. For motivating factors, see the `EngineeringTask` Tech Spec #16445. For usage examples, see [the associated RSpec](https://github.com/department-of-veterans-affairs/caseflow/blob/master/spec/models/tasks/engineering_task_spec.rb).

The `EngineeringTask` is assigned to a specific engineer when possible; otherwise it is assigned to the Caseflow user (`User.system_user`).
One use case is to create a child `EngineeringTask` to block a parent task (e.g., `BvaDispatchTask`) when the complete workflow is not yet implemented (e.g., Unrecognized Appellant work).


## What are Blocking Tasks?
### What Blocking Means

There are three general ways we use the concept of "blocking" in Caseflow, one general, and two aligned with how a case processes runs.

**General Use**
Task A is blocking task B if no work can be done on Task B until Task A is completed.  
Examples here would include Attorney Drafting Tasks blocking Judge Decision Review, Timed Hold Tasks block any task that requests it, etc.

This is implemented in two ways, via a child-task relationship of task B to task A in the task tree (eg Attorney Decision Drafting is the child of a Judge Decision Review), or by the explicit creation of Task B upon completion of Task A (eg Judge Assign Task is created when the Distribution Task completes).

**Blocks Distribution**
Tasks which block distribution are a specific case of general blocking, implemented via the child-task relationship. Tasks which block distribution are created as children of the Distribution Task. A case is ready for distribution only when all children of the Distribution Task are complete.

In Evidence Window dockets, the Evidence Submission window blocks distribution. In hearing dockets, [the hearing task & all its children](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#hearing-phase) block distribution. In Direct Review, there are no tasks blocking distribution by default.

All dockets may have their distribution blocked if they receive a Blocking Mail Task.

**Blocks Dispatch**
As of June 2020, there is _no special handling for blocking dispatch_. Only the general blocking as defined above applies.

### Non blocking

In Caseflow, nonblocking tasks can be worked in parallel.  
This is implemented by having the Tasks be on different branches. All leaf tasks on a task tree can be worked in parallel.  
Examples include an attorney creating two colocated tasks, or if a non-blocking Mail task comes in.

### The Root Task

Every Appeal has one root task. It is used as a container and tracker for the entire case's task tree. The root task is never considered blocked.

Tasks created off the Root Task can run in parallel to each other.
When any child task of the root task is completed, that task is responsible for creating a new sibling on the root task to track the next stage of the case process.
For example, when a Distribution task is completed, the Judge Assign task is created. When the Judge Assign task is completed, the Judge Decision Review Task with a child Attorney Decision Drafting tasks are created.

### Mail Tasks

Most tasks of the same type tend to behave the same. Mail Tasks are the exception to this. Some Mail tasks block Distribution, if the case has not yet been sent to a judge for drafting the decision.

These mail tasks will block case distribution if they come in before the distribution, pulled June 2020.

```ruby
> MailTask.blocking_subclasses
=> ["CongressionalInterestMailTask",
 "ExtensionRequestMailTask",
 "FoiaRequestMailTask",
 "HearingRelatedMailTask",
 "PowerOfAttorneyRelatedMailTask",
 "PrivacyActRequestMailTask",
 "PrivacyComplaintMailTask"]
```
Other Mail Tasks are worked in parallel.

Any mail tasks that come in after a case has been distributed are created off the root task, and worked in parallel.

See the [Mail Tasks TaskTree Documentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#mailtasks)

### Exceptions

`DecisionReviewTask` and `Dispatch::Task`s may follow different paradigms.

Hearing Tasks follow general blocking, but may have different flow within the Hearing Task Tree Branch.

In Queue, User tasks do not block their matching parent Organization Task. Rather, the pair tend to complete at the same time. 
Organizations tasks are used by Organization admin users to track the appeal as it is under control of their org. They also give the admin users access to reassign or cancel that user task, as appropriate.
User tasks are assigned to individual users within the org to track to actual work of the case.

### Docket Switch Tasks


#### Task Behavior
The docket switch flow begins with the creation of a `DocketSwitchMailTask` by a user at the Clerk of the Board. This task gets created as a child of the `DistributionTask` to block distribution to a VLJ while the docket switch request is under review. The task gets assigned to that same user whereupon they will send the request to switch dockets to a VLJ. Sending the request to a judge closes the `DocketSwitchMailTask` with a status of `completed`, closes the parent `DocketSwitchMailTask` assigned to the Organization as well, and creates a `DocketSwitchRulingTask`. Once the VLJ decides to either grant or deny the request to switch dockets, that in turn will create either a `DocketSwitchGrantedTask` or `DocketSwitchDeniedTask` and close the `DocketSwitchRulingTask` with a status of `completed`. These are the final tasks within the docket switch task flow. 

##### Docket Switch Granted Task Tree
```
Appeal 1639 (D 210726-1639 Original) ────── │ ID   │ STATUS    │ ASGN_BY     │ ASGN_TO         │ UPDATED_AT              │
└── RootTask                                │ 6876 │ cancelled │             │ Bva             │ 2021-07-27 17:39:06 UTC │
    └── DistributionTask                    │ 6877 │ cancelled │             │ Bva             │ 2021-07-27 17:43:28 UTC │
        ├── DocketSwitchMailTask            │ 6878 │ completed │             │ ClerkOfTheBoard │ 2021-07-27 17:40:40 UTC │
        │   └── DocketSwitchMailTask        │ 6879 │ completed │ COB_USER    │ COB_USER        │ 2021-07-27 17:40:40 UTC │
        └── DocketSwitchRulingTask          │ 6880 │ completed │ COB_USER    │ BVAAABSHIRE     │ 2021-07-27 17:43:28 UTC │
            └── DocketSwitchGrantedTask     │ 6881 │ completed │ BVAAABSHIRE │ ClerkOfTheBoard │ 2021-07-27 17:43:28 UTC │
                └── DocketSwitchGrantedTask │ 6882 │ completed │ BVAAABSHIRE │ COB_USER        │ 2021-07-27 17:43:29 UTC │
                                            └────────────────────────────────────────────────────────────────────────────┘
```
##### Docket Switch Denied Task Tree
```
Appeal 1640 (E 210726-1639 Original) ───── │ ID   │ STATUS    │ ASGN_BY     │ ASGN_TO         │ UPDATED_AT              │
└── RootTask                               │ 6883 │ on_hold   │             │ Bva             │ 2021-07-27 17:43:28 UTC │
    ├── DistributionTask                   │ 6884 │ on_hold   │             │ Bva             │ 2021-07-27 17:43:28 UTC │
    │   ├── EvidenceSubmissionWindowTask   │ 6885 │ assigned  │             │ MailTeam        │ 2021-07-27 17:43:28 UTC │
    │   ├── DocketSwitchMailTask           │ 6887 │ completed │             │ ClerkOfTheBoard │ 2021-07-27 17:45:37 UTC │
    │   │   └── DocketSwitchMailTask       │ 6888 │ completed │ COB_USER    │ COB_USER        │ 2021-07-27 17:45:37 UTC │
    │   └── DocketSwitchRulingTask         │ 6889 │ completed │ COB_USER    │ BVAAABSHIRE     │ 2021-07-27 17:49:06 UTC │
    │       └── DocketSwitchDeniedTask     │ 6890 │ completed │ BVAAABSHIRE │ ClerkOfTheBoard │ 2021-07-27 17:49:05 UTC │
    │           └── DocketSwitchDeniedTask │ 6891 │ completed │ BVAAABSHIRE │ COB_USER        │ 2021-07-27 17:49:06 UTC │
```
#### Task Creation

Upon switching an appeal to a different docket type, and in turn creating a new appeal stream, the task creation process largely mimics when intaking a new appeal. All new appeals will have a `RootTask` and `DistributionTask` with a status of `on_hold`. The new appeal will also have a `DocketSwitchGrantedTask` with a status of `complete` which is shown in the Case Timeline and requires no action. 

When switching to a `DirectReview` docket, an `InformalHearingPresentation` task will be created as a child of the `DistributionTask` if the appellant has a VSO representing them and that VSO is configured to perform IHPs. 

When switching to an `EvidenceSubmission` docket, an `EvidenceSubmissionWindowTask` will be automatically created as a child of the `DistributionTask` and with a status of `assigned`. This task signifies the 90-day window during which an appellant may submit additional evidence before the appeal gets distributed to a VLJ. An `InformalHearingPresentation` task will also be created as a child of the `DistributionTask` after the 90-day evidence submission window is complete if the appellant has a VSO representing them and that VSO is configured to perform IHPs. 

When switching to a `Hearing` docket, a `Hearing` task will be automatically created as a child of the `DistributionTask` and a `ScheduleHearingTask` will be automatically created as a child of the `Hearing` task. Once these tasks are completed by scheduling and holding a hearing, the appeal will be ready for distribution to a VLJ.

#### Tasks ineligible to switch dockets
Tasks listed below are ineligible to switch dockets. All other tasks will default to switching dockets but the user granting the request can remove these tasks from switching in the UI
  - Open tasks with children
  - `RootTask` - Newly created for new appeal stream
  - `DistributionTask` - Newly created for new appeal stream
  - `EvidenceSubmissionWindowTask` & children
  - `HearingTask` & children
  - `DocketSwitch` tasks - New `DocketSwitchGrantedTask` created for new appeal stream 

### Tasks that should have only one open at a time
There are certain task types that an appeal should have only one open instance of at a time.  Team Echo is currently working with the board to confirm which task types have these restrictions.  For an evolving list, please see this github [comment](https://github.com/department-of-veterans-affairs/caseflow/issues/15220#issuecomment-896194415).
