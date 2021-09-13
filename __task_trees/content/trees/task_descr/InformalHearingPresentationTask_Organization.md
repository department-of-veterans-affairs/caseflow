| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# InformalHearingPresentationTask_Organization Description

Task stats [for DR](../docket-DR/InformalHearingPresentationTask_Organization.md), [for ES](../docket-ES/InformalHearingPresentationTask_Organization.md), [for H](../docket-H/InformalHearingPresentationTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task assigned to VSOs to submit an Informal Hearing Presentation for Veterans who have elected not to have a hearing.
* IHPs are a chance for VSOs to make final arguments before a case is sent to the Board.
* BVA typically (but not always) waits for an IHP to be submitted before making a decision.
  
* If an appeal is in the Direct Review docket, this task is automatically created as a child of DistributionTask if the
  representing VSO `should_write_ihp?(appeal)` -- see `IhpTasksFactory.create_ihp_tasks!`.
  
* For an Evidence Submission docket, this task is created as the child of DistributionTask
  after the 90 evidence submission window is complete.
<!-- class_comments:end -->

For an Evidence Submission docket, this task is created [after the 90 evidence submission window is complete](https://github.com/department-of-veterans-affairs/caseflow/blob/e82803c2cdb863b53ece9796ab1a2585739d1e5b/app/models/tasks/evidence_submission_window_task.rb#L13), also as the child of the DistributionTask.

See epic https://github.com/department-of-veterans-affairs/caseflow/issues/13700.

`InformalHearingPresentationTask`s are created when IHP tasks is automatically created by Caseflow (and assigned to a specific VSO), while [IhpColocatedTask](IhpColocatedTask_Organization.md)s are created (and assigned to the `Colocated` team) when manually created by a user.
