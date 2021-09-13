| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# EvidenceSubmissionWindowTask_Organization Description

Task stats [for DR](../docs-DR/EvidenceSubmissionWindowTask_Organization.md), [for ES](../docs-ES/EvidenceSubmissionWindowTask_Organization.md), [for H](../docs-H/EvidenceSubmissionWindowTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task that signals that a case now has a 90-day window for appellant to submit additional evidence before
  their appeal is decided (established by AMA).
* These tasks serve to block distribution until the evidence submission window is up.
* The evidence window may be waived by an appellant.
<!-- class_comments:end -->

To block distribution, EvidenceSubmissionWindowTasks are automatically created as a child of [DistributionTask](DistributionTask_Organization.md). This task is then created with a task timer is attached in order to automatically mark itself complete after 90 days via the [TaskTimerJob](https://github.com/department-of-veterans-affairs/caseflow/wiki/Timed-Tasks#tasktimer).

For Evidence Submission dockets, this task is automatically created upon intake, with the 90 day window starting on the appeal receipt date (when the NOD was received by the board). 

For hearing dockets, this task is automatically created after a hearing is held or withdrawn. If the hearing was held, the veteran has 90 days to submit evidence, starting when the hearing was scheduled. Similarly, if the hearing is withdrawn, the veteran has 90 days to submit evidence, starting when the schedule hearing task was cancelled.

Because these 90-day-window start dates can be well before the date the EvidenceSubmissionWindowTask was created, the `created_at` date on the task does not determine the start of the 90 day window, and the length of time the task was open does not map to the 90 days the veteran had to submit evidence. For instance, if an evidence submission docket appeal was intaken over 90 days _after_ the NOD was received, the evidence submission window task will have a "should be completed" date that is earlier than the task's creation date. These tasks will complete as soon as the next instance of our TaskTimerJob is run. 

See `EvidenceSubmissionWindowTask#timer_ends_at`.
See [Transcription / Evidence Submission](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#4-transcription--evidence-submission).
