| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# NoShowHearingTask_Organization Description

Task stats [for DR](../docs-DR/NoShowHearingTask_Organization.md), [for ES](../docs-ES/NoShowHearingTask_Organization.md), [for H](../docs-H/NoShowHearingTask_Organization.md) dockets.

* Task created after an appellant no-shows for a hearing.
  Gives the hearings team the options to decide how to handle the no-show hearing after the judge indicates that the appellant no-showed.

See [HearingTask](HearingTask_Organization.md) for Hearing dispositions flows, esp. the "No show" flow.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
  the no-show hearing after the judge indicates that the appellant no-showed.
  
* Task is created as a child of AssignHearingDispositionTask with a TimedHoldTask which is set to expire after
* DAYS_ON_HOLD days. Before the task expires, users can manually complete this task, postpone hearing, or create a
* ChangeHearingDispositionTask.
  
* If DAYS_ON_HOLD as passed, TaskTimerJob cleans up the TimedHoldTask and automatically completes NoShowHearingTask.
  
* Completion/cancellation of  NoShowHearingTaskcan trigger closing of parent AssignHearingDispositionTask and
  if AssignHearingDispositionTask was the last open task of grandparent HearingTask, either of the following can happen:
   - If appeal is AMA, create an EvidenceSubmissionWindowTask as child of HearingTask OR
   - If appeal is Legacy, route location according to logic in HearingTask#update_legacy_appeal_location
<!-- class_comments:end -->
