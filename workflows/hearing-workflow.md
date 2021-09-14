---
parent: Workflows
nav_order: 3
tags: ["workflow", "hearings"]
---
# Hearing Workflow

* [Caseflow Hearings](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings)
* [HearingTask](task_descr/HearingTask_Organization.md)

{% mermaid %}
graph TD

docket --> |if H| admin_actions{need hearing admin actions?}
admin_actions --> |yes| HearingAdminActionTask
HearingAdminActionTask --> ScheduleHearingTask
admin_actions --> |no| ScheduleHearingTask

ScheduleHearingTask --> AssignHearingDispositionTask

AssignHearingDispositionTask --> disposition{hearing disposition?}
disposition --> |postponed| ScheduleHearingTask
disposition --> |held| waiveES{waive Evidence Submission?}
waiveES --> |yes| TranscriptionTask
waiveES --> |no| EvidenceSubmissionWindowTask
EvidenceSubmissionWindowTask --> TranscriptionTask
TranscriptionTask --> ACD[DistributionTask]
ACD --> Decision


disposition --> |cancelled| ihpVSO{IHP-writing VSO?}
ihpVSO --> |no| EvidenceSubmissionWindowTask
ihpVSO --> |yes| IHPTask
IHPTask --> EvidenceSubmissionWindowTask

disposition --> |no show| NoShowHearingTask
NoShowHearingTask --> no_show_opt{next action}
no_show_opt --> |reschedule| ScheduleHearingTask
no_show_opt --> |recheck disposition| AssignHearingDispositionTask
no_show_opt --> |wait to distribute| 90dayEvidenceSubmissionWindowTask
90dayEvidenceSubmissionWindowTask --> ACD

disposition --> |no disposition within 48hrs| ChangeHearingDispositionTask
ChangeHearingDispositionTask --> disposition
{% endmermaid %}


## AMA Hearing

For Hearing docket.

1. Hearing Coordinator schedules hearing in docket order, resolving HearingAdminActions before hearing can be scheduled.
2. Hearing is scheduled.
3. VLJ preps for meeting using Caseflow Hearing and Reader.
  * Judge corrects issues on appeal while prepping using Intake's issue editing capability
4. Hearing happens
  * four types of hearings: travel, in person, video hearings, and virtual hearings
	* For Judges, the Daily Docket is primarily used to update the hearing's disposition or mark the case Advance on Docket (AOD). Hearing coordinators may update disposition but will more often use it to update the hearing's time.
	*  The HearingDispositionChangeJob automatically locks a Hearing Day 24 hours after the hearing date -- https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#locking-a-hearing
5. Assigns Hearing Disposition: held, cancelled, no show, postponed
  * See https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/task_descr/HearingTask_Organization.md
6. Hearing recording is transcribed and then entered into VBMS
7. Mail team intakes evidence window waiver mail
	* Veteran can send in mail, which is processed by the BVA Intake team, before the decision is written up.


## AMA Hearing vs. Legacy Hearing

A HearingDay organizes Hearings and LegacyHearings by regional office and hearing room.


