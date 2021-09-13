| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# ChangeHearingDispositionTask_Organization Description

Task stats [for DR](../docket-DR/ChangeHearingDispositionTask_Organization.md), [for ES](../docket-ES/ChangeHearingDispositionTask_Organization.md), [for H](../docket-H/ChangeHearingDispositionTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task automatically assigned to the Hearing Admin organization and/or a member of that team
  when a disposition has not been set on a hearing that was held more than 48 hours ago.
<!-- class_comments:end -->

Note that if [NoShowHearingTask](NoShowHearingTask_Organization.md)
or [TranscriptionTask](TranscriptionTask_Organization.md) are created in error,
a coordinator can create a ChangeHearingDispositionTask.
A Hearing Admin can then update the hearings disposition by completing this task on the case details pages.

See related [AssignHearingDispositionTask_Organization](AssignHearingDispositionTask_Organization.md).
