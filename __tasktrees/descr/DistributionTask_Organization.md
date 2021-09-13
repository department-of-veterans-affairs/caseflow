| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# DistributionTask_Organization Description

Task stats [for DR](../docs-DR/DistributionTask_Organization.md), [for ES](../docs-ES/DistributionTask_Organization.md), [for H](../docs-H/DistributionTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* A DistributionTask is created after the intake process is completed on an AMA case.
* This task signals that an appeal is ready for distribution to a judge, including for auto case distribution.
    - When the distribution task is assigned, Automatic Case Distribution can distribute the case to a judge.
      This completes the DistributionTask and creates a JudgeAssignTask, assigned to the judge.
  
* Expected parent task: RootTask
  
* Child tasks under the DistributionTask places it on hold and blocks the selection for distribution to a judge.
* A child task is autocreated for certain dockets -- see `InitialTasksFactory.create_subtasks!`
<!-- class_comments:end -->

For distributing cases in docket order, across all 4 dockets, to judges for decision drafting and signing.
* A variety of parameters need to be true before a case is automatically distributed to a judge.
  * For example, all blocking tasks need to be complete/cancelled (e.g. Evidence Submission docket or Hearing docket evidence windows, no blocking mail tasks, etc.) and the Distribution Task needs to be in the status of assigned.
* Hearing docket and Evidence Window docket related tasks that block distribution:
  * Evidence Window Submission tasks (e.g. for a hearing or evidence window appeal)
  * Transcription tasks
* Other blocking tasks:
  * Translation tasks
  * Informal Hearing Presentation tasks
* Mail tasks that block distribution: You can check whether any given Mail Task is blocked via their function `blocking?` returning true - see [code here](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/tasks/mail_task.rb#L23)
  * Congressional Inquiries
  * FOIA request
  * Privacy act request
  * Privacy complaint
  * Power of attorney related
  * Extension request
  * Hearing related

* A child task is autocreated for certain dockets -- see `InitialTasksFactory.create_subtasks!`
  * If an appeal is in the Hearing docket, a [HearingTask](HearingTask_Organization.md) is automatically created as a child of the DistributionTask.
  * If an appeal is in the Evidence Submission docket, a child [EvidenceSubmissionWindowTask](EvidenceSubmissionWindowTask_Organization.md) is automatically created.
  * Otherwise, a child [InformalHearingPresentationTask](InformalHearingPresentationTask_Organization.md) is automatically created if the representing VSO `should_write_ihp?(appeal)` -- see `IhpTasksFactory.create_ihp_tasks!`.

An `active` DistributionTask is able to be selected by the Automatic Case Distribution process, which will complete the Distribution task and create a [JudgeAssignTask_User](JudgeAssignTask_User.md).

Regarding [MailTasks](tasks-overview.md#mailtasks):
* If a mail task comes in before Distribution is complete that would block Distribution, that mail task is created as a child of the Distribution Task and places the DistributionTask on hold.
* If a non-blocking mail task comes in, it is created as a child of the root task, sibling to the Distribution Task, and thus does not block distribution.

## FAQ
### Why is HearingTask a child of DistributionTask?
Because Hearing-docket cases cannot be distributed until the HearingTasks are all complete.
The [HearingTask](HearingTask_Organization.md) doesn't complete until the hearings process is complete, which serves to block the DistributionTask.

### Should DistributionTask be completed when HearingTask is completed?
No, the DistributionTask should be moved to an active state if it was the last open child task of the DistributionTask.

