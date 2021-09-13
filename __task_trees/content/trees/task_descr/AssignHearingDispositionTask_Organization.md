| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# AssignHearingDispositionTask_Organization Description

Task stats [for DR](../docket-DR/AssignHearingDispositionTask_Organization.md), [for ES](../docket-ES/AssignHearingDispositionTask_Organization.md), [for H](../docket-H/AssignHearingDispositionTask_Organization.md) dockets.

After the hearing is addressed in some way, users assign a disposition to the hearing (held, cancelled, no show, postponed), which creates child task(s). Once those child task(s) are completed, the AssignHearingDispositionTask will be completed. Different task structures result based on the hearing's disposition.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask
  is completed.
  
* When the associated hearing's disposition is set, the appropriate tasks are set as children
    - held: For legacy, task is set to be completed; for AMA, TranscriptionTask is created as child and
          EvidenceSubmissionWindowTask is also created as child unless the veteran/appellant has waived
          the 90 day evidence hold.
    - Cancelled: Task is cancelled and hearing is withdrawn where if appeal is AMA, EvidenceWindowSubmissionWindow
                 task is created as a child of RootTask if it does not exist and if appeal is legacy, vacols field
                 `bfha` and `bfhr` are updated.
    - No show: NoShowHearingTask is created as a child of this task
    - Postponed: 2 options: Schedule new hearing or cancel HearingTask tree and create new ScheduleHearingTask.
  
* The task is marked complete when the children tasks are completed.
  
* If this task is the last closed task for the hearing subtree and there are no more open HearingTasks,
  the logic in HearingTask#when_child_task_completed properly handles routing or creating ihp task.
<!-- class_comments:end -->

See: 
* [ScheduleHearingTask](ScheduleHearingTask_Organization.md)
* possible children tasks: [TranscriptionTask_Organization](TranscriptionTask_Organization.md), [EvidenceSubmissionWindowTask_Organization](EvidenceSubmissionWindowTask_Organization.md)
* [HearingTask](HearingTask_Organization.md) for Hearing dispositions flows
* [Assign a Disposition](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#3-assign-a-disposition)
* 