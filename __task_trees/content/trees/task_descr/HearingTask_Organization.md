| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# HearingTask_Organization Description

Task stats [for DR](../docket-DR/HearingTask_Organization.md), [for ES](../docket-ES/HearingTask_Organization.md), [for H](../docket-H/HearingTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* A task used to track all related hearing subtasks.
* A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
  in order to schedule a hearing, hold it, and mark the disposition.
* If an appeal is in the Hearing docket, a HearingTask is automatically created as a child of DistributionTask.
<!-- class_comments:end -->

See [Hearings Task Model](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearings-task-model).

## Hearing dispositions flows
* Postponed - Hearing is postponed and:
  * the Veteran is immediately re-scheduled: Assign Hearing Disposition Task is completed and the Hearing Task is automatically closed. A new Hearing Task and Assign Hearing Disposition Task are created
  * the Veteran is NOT immediately re-scheduled: Assign Hearing Disposition Task is completed and the Hearing Task is automatically closed. A new Hearing Task and Schedule Hearing Task are created
* Held - Assign Hearing Disposition Task is completed and the Hearing Task is automatically closed as complete. Since all hearings are required to be transcribed, a Transcription Task is created and assigned to the Hearing Branch. Also, AMA allows the Veteran 90 days to submit evidence after a hearing, so an Evidence window task is created. The Evidence Window tasks expires in 90 days
  * If the Veteran waives their Evidence Window, Assign Hearing Disposition Task is completed and the Hearing Task is automatically closed as complete. Since all hearings are required to be transcribed, a Transcription Task is created and assigned to the Hearing Branch. The Evidence Submission task is never created.
* Cancelled - The hearing request is withdrawn/cancelled (after the hearing was scheduled). Assign Hearing Disposition Task is completed and the Hearing Task is automatically closed. The Veteran remains in the hearing docket, and still has the chance to submit evidence and waits 90 days before being distributed to a judge. If the Veteran has an IHP-writing VSO, an IHP task is also created.
* No Show - Assign Hearing Disposition Task is completed and a No Show Hearing Task is created as a child to it, assigned to the Hearing Branch. The No Show Hearing Task has 3 options: 
  * Mark the No Show Hearing Task as complete, and postpone the hearing to be scheduled again 
  * Send for hearing disposition change (because perhaps No Show was incorrect)
  * Mark the No Show Hearing Task as complete, essentially letting it wait to be distributed to a judge.  No Show Hearing Task is marked complete, the 90 day evidence window task is assigned. When it expires, the case can be distributed to a judge for decision.

