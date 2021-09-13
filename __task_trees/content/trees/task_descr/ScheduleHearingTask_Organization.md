| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# ScheduleHearingTask_Organization Description

At the end of Intake, if the Veteran chose the Hearing docket, this task with a [HearingTask](HearingTask_Organization.md) parent is created. 

Task stats [for DR](../docket-DR/ScheduleHearingTask_Organization.md), [for ES](../docket-ES/ScheduleHearingTask_Organization.md), [for H](../docket-H/ScheduleHearingTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task to schedule a hearing for a veteran making a claim.
  
* When this task is created, HearingTask is created as the parent task in the appeal tree.
  
* For AMA appeals, task is created by the intake process for any appeal electing to have a hearing.
* For Legacy appeals, Geomatching is responsible for finding all appeals in VACOLS ready to be scheduled
  and creating a ScheduleHearingTask for each of them.
  
* A coordinator can block this task by creating a HearingAdminActionTask for some reasons listed
  here: https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#2-schedule-veteran
  
* This task also allows coordinators to withdraw unscheduled hearings (i.e cancel this task)
* For AMA, this creates an EvidenceSubmissionWindowTask as child of parent HearingTask and for legacy appeal,
  vacols field `bfha` and `bfhr` are updated.
  
* If cancelled, the parent HearingTask is automatically closed. If this task is the last closed task for the
  hearing subtree and there are no more open HearingTasks, the logic in HearingTask#when_child_task_completed
  properly handles routing or creating ihp task.
  
* If completed, an AssignHearingDispositionTask is created as a child of HearingTask.
<!-- class_comments:end -->

See [Schedule Veteran](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#2-schedule-veteran)

