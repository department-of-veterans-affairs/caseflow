---
title: "Tasks Overview"
categories: "overview"
---

| [README](../intro/README.md) | [All tasks](alltasks.md) | [DR tasks](docket-DR/tasklist.md) | [ES tasks](docket-ES/tasklist.md) | [H tasks](docket-H/tasklist.md) |

See [How to use](../README.md#how-to-use-and-interpret-this-documentation) for a description of the docket types: Direct Review (DR), Evidence Submission (ES), and Hearing (H).

Appeals Process: [mural](https://app.mural.co/t/workqueue2001/m/workqueue2001/1561671251478/5b71dc3125e2075289be03161b4cf6f42896184d)

# Tasks Overview

The tasks presented on this page are organized into phases of the appeal process:
* [Regional Office Phase](#regional-office-phase)
* [Intake Phase](#intake-phase)
* [Hearing Phase](#hearing-phase)
* [Decision Phase](#decision-phase)
* [Quality Review Phase](#quality-review-phase)
* [Dispatch Phase](#dispatch-phase)

How to interpret bullets and subbullets in "Associated tasks" sections:
* When a child task is always (or almost always) a child of a specific parent task, it is shown as a subbullet under the associated parent task.
* When a task is noted as only occurring for certain dockets, all child tasks also only occur for those specified dockets.
* The parent-child relationships were inferred by examining the **Parent Tasks** section of each task page for all dockets (e.g., [Parent Tasks for JudgeDecisionReviewTask_User](docket-DR/JudgeDecisionReviewTask_User.md#parent-and-child-tasks)).  The frequent parent-child relationships for each docket type ([DR:parent-child](docket-DR/freq-parentchild.md), [ES:parent-child](docket-ES/freq-parentchild.md) and [H:parent-child](docket-H/freq-parentchild.md)) was also helpful.

At the bottom of the page are:
* [MailTasks](#mailtasks)
* [other tasks](#other-tasks) and
* [deprecated tasks](#deprecated-tasks)

## Regional Office Phase
Background:
* [VSOs](https://github.com/department-of-veterans-affairs/caseflow/wiki/VSOs)

Associated tasks:
* [RootTask_Organization](task_descr/RootTask_Organization.md) - not specific this phase
  * [TrackVeteranTask_Organization](task_descr/TrackVeteranTask_Organization.md) - can happen at any phase


## Intake Phase
Background:
* [Intake](https://github.com/department-of-veterans-affairs/appeals-team/wiki/Intake)
* [Caseflow Intake](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Intake)
  * [Intake Data Model](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model)
* [Issues presentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Caseflow%20Projects/Intake/AMA%20ISSUES.pdf)
* [Intake Search training video](https://www.youtube.com/watch?v=_M-5NXVMDZs&feature=youtu.be)

Tasks created upon Intake Phase success (see [`Appeal#create_tasks_on_intake_success!`](https://github.com/department-of-veterans-affairs/caseflow/blob/f881ded814011e11b6adaa88038b4afb8950e7c2/app/models/appeal.rb#L421)):
* [TrackVeteranTask_Organization](task_descr/TrackVeteranTask_Organization.md)
* [DistributionTask_Organization](task_descr/DistributionTask_Organization.md)
  * [EvidenceSubmissionWindowTask_Organization](task_descr/EvidenceSubmissionWindowTask_Organization.md) if in ES docket
  * [ScheduleHearingTask_Organization](task_descr/ScheduleHearingTask_Organization.md) if in H docket
  * [InformalHearingPresentationTask_Organization](task_descr/InformalHearingPresentationTask_Organization.md)
    if the representing VSO [`should_write_ihp?(appeal)`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/workflows/ihp_tasks_factory.rb#L10); occurs only in DR and ES dockets
    * [InformalHearingPresentationTask_User](task_descr/InformalHearingPresentationTask_User.md)
* [TranslationTask_Organization](task_descr/TranslationTask_Organization.md)
  * [TranslationTask_User](task_descr/TranslationTask_User.md)
* [VeteranRecordRequest_Organization](task_descr/VeteranRecordRequest_Organization.md)

The following fake task tree merges several appeals to exemplify parent-child task relationships associated with the Intake and prior phases
(Click on task links above to browse for task trees of actual appeals):

{{< mermaid >}}
flowchart TD
style 0.RootTask fill:#eeeeee
  0.RootTask(["0.RootTask\n(organization)"])
style 1.TrackVeteranTask fill:#cccccc
  1.TrackVeteranTask(["1.TrackVeteranTask\n(organization)"])
style 2.DistributionTask fill:#dddddd
  2.DistributionTask>"2.DistributionTask\n(organization)"]
style 3.InformalHearingPresentationTask fill:#fdb462
  3.InformalHearingPresentationTask["3.InformalHearingPresentationTask\n(organization)"]
style 4.TranslationTask fill:#bebada
  4.TranslationTask["4.TranslationTask\n(organization)"]
style 5.TranslationTask fill:#bebada
  5.TranslationTask["5.TranslationTask\n(user)"]
style 6.InformalHearingPresentationTask fill:#fdb462
  6.InformalHearingPresentationTask["6.InformalHearingPresentationTask\n(user)"]
style 7.VeteranRecordRequest fill:#ffed6f
  7.VeteranRecordRequest["7.VeteranRecordRequest\n(organization)"]
0.RootTask --> 1.TrackVeteranTask
0.RootTask --> 2.DistributionTask
2.DistributionTask --> 3.InformalHearingPresentationTask
2.DistributionTask --> 4.TranslationTask
4.TranslationTask --> 5.TranslationTask
3.InformalHearingPresentationTask --> 6.InformalHearingPresentationTask
0.RootTask --> 7.VeteranRecordRequest
{{< /mermaid >}}

## Hearing Phase
Background:
* [Caseflow Hearings](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings)

Associated tasks:
* [RootTask_Organization](task_descr/RootTask_Organization.md) - not specific this phase
  * [DistributionTask_Organization](task_descr/DistributionTask_Organization.md)
    * [HearingTask_Organization](task_descr/HearingTask_Organization.md) only in Hearing docket; almost always a child task of DistributionTask_Organization
      * [ScheduleHearingTask_Organization](task_descr/ScheduleHearingTask_Organization.md)
        * [**HearingAdminActionTask**](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/tasks/hearing_admin_action_task.rb) -
          blocks scheduling a Veteran for a hearing.
          A few scenarios (e.g., missing data or Veteran situations) automatically create HearingAdminTasks.
          A hearing coordinator must resolve these before scheduling a Veteran.
          Subclasses of various hearing admin actions are listed below.
        * [HearingAdminActionVerifyAddressTask_Organization](task_descr/HearingAdminActionVerifyAddressTask_Organization.md)
          * [HearingAdminActionVerifyAddressTask_User](task_descr/HearingAdminActionVerifyAddressTask_User.md)
        * [HearingAdminActionOtherTask_Organization](task_descr/HearingAdminActionOtherTask_Organization.md)
            * [HearingAdminActionOtherTask_User](task_descr/HearingAdminActionOtherTask_User.md)
        * [HearingAdminActionForeignVeteranCaseTask_Organization](task_descr/HearingAdminActionForeignVeteranCaseTask_Organization.md)
        * [HearingAdminActionFoiaPrivacyRequestTask_Organization](task_descr/HearingAdminActionFoiaPrivacyRequestTask_Organization.md)
          * [HearingAdminActionFoiaPrivacyRequestTask_User](task_descr/HearingAdminActionFoiaPrivacyRequestTask_User.md)
        * HearingAdminActionContestedClaimantTask - 0 occurrences
      * [AssignHearingDispositionTask_Organization](task_descr/AssignHearingDispositionTask_Organization.md) or
        [ChangeHearingDispositionTask_Organization](task_descr/ChangeHearingDispositionTask_Organization.md)
        * [NoShowHearingTask_Organization](task_descr/NoShowHearingTask_Organization.md)
          * [NoShowHearingTask_User](task_descr/NoShowHearingTask_User.md)
          * [TimedHoldTask_Organization](task_descr/TimedHoldTask_Organization.md)
        * [TranscriptionTask_Organization](task_descr/TranscriptionTask_Organization.md) only in Hearing docket (1 occurrence in ES docket); can also be a child of [MissingHearingTranscriptsColocatedTask_Organization](task_descr/MissingHearingTranscriptsColocatedTask_Organization.md)
* [EvidenceSubmissionWindowTask_Organization](task_descr/EvidenceSubmissionWindowTask_Organization.md) only in ES and H dockets

The following fake task tree merges several appeals to exemplify parent-child task relationships associated with the Hearing and prior phases
(Click on task links above to browse for task trees of actual appeals):

{{< mermaid >}}
flowchart TD
style 0.RootTask fill:#eeeeee
  0.RootTask(["0.RootTask\n(organization)"])
style 1.TrackVeteranTask fill:#cccccc
  1.TrackVeteranTask(["1.TrackVeteranTask\n(organization)"])
style 2.DistributionTask fill:#dddddd
  2.DistributionTask>"2.DistributionTask\n(organization)"]

style 3.HearingTask fill:#fb8072
  3.HearingTask["3.HearingTask\n(organization)"]
style 4.ScheduleHearingTask fill:#80b1d3
  4.ScheduleHearingTask["4.ScheduleHearingTask\n(organization)"]

style 7.HearingAdminActionVerifyAddressTask fill:#ffed6f
  7.HearingAdminActionVerifyAddressTask["7.HearingAdminActionVerifyAddressTask\n(organization)"]
style 8.HearingAdminActionVerifyAddressTask fill:#ffed6f
  8.HearingAdminActionVerifyAddressTask["8.HearingAdminActionVerifyAddressTask\n(user)"]
4.ScheduleHearingTask --> 7.HearingAdminActionVerifyAddressTask
7.HearingAdminActionVerifyAddressTask --> 8.HearingAdminActionVerifyAddressTask

style 9.HearingAdminActionFoiaPrivacyRequestTask fill:#ffed6f
  9.HearingAdminActionFoiaPrivacyRequestTask["9.HearingAdminActionFoiaPrivacyRequestTask\n(organization)"]
style 10.HearingAdminActionFoiaPrivacyRequestTask fill:#ffed6f
  10.HearingAdminActionFoiaPrivacyRequestTask["10.HearingAdminActionFoiaPrivacyRequestTask\n(user)"]
4.ScheduleHearingTask --> 9.HearingAdminActionFoiaPrivacyRequestTask
9.HearingAdminActionFoiaPrivacyRequestTask --> 10.HearingAdminActionFoiaPrivacyRequestTask

style 5.TranslationTask fill:#bebada
  5.TranslationTask["5.TranslationTask\n(organization)"]
style 6.TranslationTask fill:#bebada
  6.TranslationTask["6.TranslationTask\n(user)"]
3.HearingTask --> 5.TranslationTask
5.TranslationTask --> 6.TranslationTask

style 11.AssignHearingDispositionTask fill:#8dd3c7
  11.AssignHearingDispositionTask["11.AssignHearingDispositionTask\n(organization)"]

style 12.NoShowHearingTask fill:#b3de69
  12.NoShowHearingTask["12.NoShowHearingTask\n(organization)"]
style 13.TimedHoldTask fill:#fccde5
  13.TimedHoldTask["13.TimedHoldTask\n(organization)"]
style 14.NoShowHearingTask fill:#b3de69
  14.NoShowHearingTask["14.NoShowHearingTask\n(user)"]
11.AssignHearingDispositionTask --> 12.NoShowHearingTask
12.NoShowHearingTask --> 13.TimedHoldTask
12.NoShowHearingTask --> 14.NoShowHearingTask

style 15.ChangeHearingDispositionTask fill:#d9d9d9
  15.ChangeHearingDispositionTask["15.ChangeHearingDispositionTask\n(organization)"]
style 16.TranscriptionTask fill:#fb8072
  16.TranscriptionTask["16.TranscriptionTask\n(organization)"]
style 17.EvidenceSubmissionWindowTask fill:#fccde5
  17.EvidenceSubmissionWindowTask["17.EvidenceSubmissionWindowTask\n(organization)"]
3.HearingTask --> 15.ChangeHearingDispositionTask
15.ChangeHearingDispositionTask --> 16.TranscriptionTask
15.ChangeHearingDispositionTask --> 17.EvidenceSubmissionWindowTask

0.RootTask --> 1.TrackVeteranTask
0.RootTask --> 2.DistributionTask
3.HearingTask --> 4.ScheduleHearingTask
2.DistributionTask --> 3.HearingTask
3.HearingTask --> 11.AssignHearingDispositionTask
{{< /mermaid >}}

## Decision Phase

Background:
* [Caseflow Queue](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Queue)
  * [VLJ Support](https://github.com/department-of-veterans-affairs/caseflow/wiki/VLJ-Support), [interactions with other teams (FOIA/Privacy Act, IHP, ...)](https://github.com/department-of-veterans-affairs/caseflow/wiki/VLJ-Support-Staff-nteractions-with-other-teams)
  * [Organizations](https://github.com/department-of-veterans-affairs/caseflow/wiki/Organizations)
  * [Fixing task trees](https://github.com/department-of-veterans-affairs/caseflow/wiki/Fixing-task-trees)
  * [structure_render](https://github.com/department-of-veterans-affairs/caseflow/wiki/Investigating-and-diagnosing-issues) and [task tree render](https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render)
* [Caseflow Reader](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader)
* [Routing of admin actions changed (deprecating some Colocated tasks)](https://github.com/department-of-veterans-affairs/caseflow/issues/11113)

Associated tasks:
* [RootTask_Organization](task_descr/RootTask_Organization.md) - not specific this phase
  * [JudgeAssignTask_User](task_descr/JudgeAssignTask_User.md)
    * [AttorneyTask_User](task_descr/AttorneyTask_User.md)
  * [JudgeDecisionReviewTask_User](task_descr/JudgeDecisionReviewTask_User.md)
    * [AttorneyTask_User](task_descr/AttorneyTask_User.md)
    * [AttorneyRewriteTask_User](task_descr/AttorneyRewriteTask_User.md)

Colocated tasks are usually children of [AttorneyTasks](AttorneyTask_User.md):
<details><summary>(Click left triangle to expand list of colocated tasks, ordered by occurrence count.)</summary>

  * [OtherColocatedTask_Organization](task_descr/OtherColocatedTask_Organization.md)
    * [OtherColocatedTask_User](task_descr/OtherColocatedTask_User.md)
  * [IhpColocatedTask_Organization](task_descr/IhpColocatedTask_Organization.md)
    * [IhpColocatedTask_User](task_descr/IhpColocatedTask_User.md)
  * [FoiaColocatedTask_Organization](task_descr/FoiaColocatedTask_Organization.md)
    * [FoiaTask_Organization](task_descr/FoiaTask_Organization.md)
      * [FoiaTask_User](task_descr/FoiaTask_User.md)
  * [PreRoutingFoiaColocatedTask_Organization](task_descr/PreRoutingFoiaColocatedTask_Organization.md) - deprecated? #13266
    * [PreRoutingFoiaColocatedTask_User](task_descr/PreRoutingFoiaColocatedTask_User.md) - deprecated? #13266
  * [OtherColocatedTask_User](task_descr/OtherColocatedTask_User.md) or [deprecated? PreRoutingFoiaColocatedTask_User](task_descr/PreRoutingFoiaColocatedTask_User.md)
    * [PrivacyActTask_Organization](task_descr/PrivacyActTask_Organization.md)
  * [PreRoutingTranslationColocatedTask_Organization](task_descr/PreRoutingTranslationColocatedTask_Organization.md) only in DR and ES dockets - deprecated? #11113
    * [PreRoutingTranslationColocatedTask_User](task_descr/PreRoutingTranslationColocatedTask_User.md) - deprecated? #11113
      * [PrivacyActTask_User](task_descr/PrivacyActTask_User.md)
  * [PreRoutingMissingHearingTranscriptsColocatedTask_Organization](task_descr/PreRoutingMissingHearingTranscriptsColocatedTask_Organization.md) - deprecated? #11113
    * [PreRoutingMissingHearingTranscriptsColocatedTask_User](task_descr/PreRoutingMissingHearingTranscriptsColocatedTask_User.md) - deprecated? #11113
  * [MissingRecordsColocatedTask_Organization](task_descr/MissingRecordsColocatedTask_Organization.md)
    * [MissingRecordsColocatedTask_User](task_descr/MissingRecordsColocatedTask_User.md)
  * [ScheduleHearingColocatedTask_Organization](task_descr/ScheduleHearingColocatedTask_Organization.md)
    * [ScheduleHearingColocatedTask_User](task_descr/ScheduleHearingColocatedTask_User.md)
  * [StayedAppealColocatedTask_Organization](task_descr/StayedAppealColocatedTask_Organization.md)
    * [StayedAppealColocatedTask_User](task_descr/StayedAppealColocatedTask_User.md)
  * [ExtensionColocatedTask_Organization](task_descr/ExtensionColocatedTask_Organization.md)
    * [ExtensionColocatedTask_User](task_descr/ExtensionColocatedTask_User.md)
  * [HearingClarificationColocatedTask_Organization](task_descr/HearingClarificationColocatedTask_Organization.md)
    * [HearingClarificationColocatedTask_User](task_descr/HearingClarificationColocatedTask_User.md)
  * [PoaClarificationColocatedTask_Organization](task_descr/PoaClarificationColocatedTask_Organization.md)
    * [PoaClarificationColocatedTask_User](task_descr/PoaClarificationColocatedTask_User.md)
  * [TranslationColocatedTask_Organization](task_descr/TranslationColocatedTask_Organization.md)
  * [AddressVerificationColocatedTask_Organization](task_descr/AddressVerificationColocatedTask_Organization.md)
    * [AddressVerificationColocatedTask_User](task_descr/AddressVerificationColocatedTask_User.md)
  * [AojColocatedTask_Organization](task_descr/AojColocatedTask_Organization.md)
    * [AojColocatedTask_User](task_descr/AojColocatedTask_User.md)
  * [NewRepArgumentsColocatedTask_Organization](task_descr/NewRepArgumentsColocatedTask_Organization.md)
    * [NewRepArgumentsColocatedTask_User](task_descr/NewRepArgumentsColocatedTask_User.md)
  * [MissingHearingTranscriptsColocatedTask_Organization](task_descr/MissingHearingTranscriptsColocatedTask_Organization.md)
  * [PendingScanningVbmsColocatedTask_Organization](task_descr/PendingScanningVbmsColocatedTask_Organization.md)
    * [PendingScanningVbmsColocatedTask_User](task_descr/PendingScanningVbmsColocatedTask_User.md)
  * [UnaccreditedRepColocatedTask_Organization](task_descr/UnaccreditedRepColocatedTask_Organization.md)
    * [UnaccreditedRepColocatedTask_User](task_descr/UnaccreditedRepColocatedTask_User.md)
</details>

The following fake task tree merges several appeals to exemplify parent-child task relationships associated with the Decision phase
(Click on task links above to browse for task trees of actual appeals):

{{< mermaid >}}
flowchart TD
style 0.RootTask fill:#eeeeee
  0.RootTask(["0.RootTask\n(organization)"])
style 5.JudgeAssignTask fill:#ccebc5
  5.JudgeAssignTask[\"5.JudgeAssignTask\n(user)"/]
style 6.AttorneyTask fill:#bc80bd
  6.AttorneyTask["6.AttorneyTask\n(user)"]
style 7.OtherColocatedTask fill:#80b1d3
  7.OtherColocatedTask["7.OtherColocatedTask\n(organization)"]
style 8.OtherColocatedTask fill:#80b1d3
  8.OtherColocatedTask["8.OtherColocatedTask\n(user)"]

0.RootTask --> 5.JudgeAssignTask
5.JudgeAssignTask --> 6.AttorneyTask
6.AttorneyTask --> 7.OtherColocatedTask
7.OtherColocatedTask --> 8.OtherColocatedTask

style 9.JudgeDecisionReviewTask fill:#d9d9d9
  9.JudgeDecisionReviewTask[["9.JudgeDecisionReviewTask\n(user)"]]
style 10.AttorneyTask fill:#bc80bd
  10.AttorneyTask["10.AttorneyTask\n(user)"]
style 19.AttorneyRewriteTask fill:#b3de69
  19.AttorneyRewriteTask["19.AttorneyRewriteTask\n(user)"]
0.RootTask --> 9.JudgeDecisionReviewTask
9.JudgeDecisionReviewTask --> 10.AttorneyTask
9.JudgeDecisionReviewTask --> 19.AttorneyRewriteTask

style 11.IhpColocatedTask fill:#bcffff
  11.IhpColocatedTask["11.IhpColocatedTask\n(organization)"]
style 12.IhpColocatedTask fill:#bcffff
  12.IhpColocatedTask["12.IhpColocatedTask\n(user)"]
style 13.MissingRecordsColocatedTask fill:#bebada
  13.MissingRecordsColocatedTask["13.MissingRecordsColocatedTask\n(organization)"]
style 14.MissingRecordsColocatedTask fill:#bebada
  14.MissingRecordsColocatedTask["14.MissingRecordsColocatedTask\n(user)"]

10.AttorneyTask --> 11.IhpColocatedTask
11.IhpColocatedTask --> 12.IhpColocatedTask
10.AttorneyTask --> 13.MissingRecordsColocatedTask
13.MissingRecordsColocatedTask --> 14.MissingRecordsColocatedTask

style 15.TranslationColocatedTask fill:#ccebc5
  15.TranslationColocatedTask["15.TranslationColocatedTask\n(organization)"]
style 16.TranslationTask fill:#bcbd22
  16.TranslationTask["16.TranslationTask\n(organization)"]
10.AttorneyTask --> 15.TranslationColocatedTask
15.TranslationColocatedTask --> 16.TranslationTask

style 17.MissingHearingTranscriptsColocatedTask fill:#eba5ea
  17.MissingHearingTranscriptsColocatedTask["17.MissingHearingTranscriptsColocatedTask\n(organization)"]
style 18.TranscriptionTask fill:#fb8072
  18.TranscriptionTask["18.TranscriptionTask\n(organization)"]
10.AttorneyTask --> 17.MissingHearingTranscriptsColocatedTask
17.MissingHearingTranscriptsColocatedTask --> 18.TranscriptionTask
{{< /mermaid >}}

## Quality Review Phase
Background:
* [Quality Review](https://github.com/department-of-veterans-affairs/caseflow/wiki/Quality-Review)

Associated tasks:
* [QualityReviewTask_Organization](task_descr/QualityReviewTask_Organization.md)
  * [QualityReviewTask_User](task_descr/QualityReviewTask_User.md)
    * [JudgeQualityReviewTask_User](task_descr/JudgeQualityReviewTask_User.md)
      * [AttorneyQualityReviewTask_User](task_descr/AttorneyQualityReviewTask_User.md)

The following fake task tree merges several appeals to exemplify parent-child task relationships associated with the Quality Review phase
(Click on task links above to browse for task trees of actual appeals):

{{< mermaid >}}
flowchart TD
style 0.RootTask fill:#eeeeee
  0.RootTask(["0.RootTask\n(organization)"])
style 3.QualityReviewTask fill:#fdb462
  3.QualityReviewTask[\"3.QualityReviewTask\n(organization)"\]
style 4.QualityReviewTask fill:#fdb462
  4.QualityReviewTask[\"4.QualityReviewTask\n(user)"\]
style 5.JudgeQualityReviewTask fill:#bc80bd
  5.JudgeQualityReviewTask["5.JudgeQualityReviewTask\n(user)"]
style 6.AttorneyQualityReviewTask fill:#bc80bd
  6.AttorneyQualityReviewTask["6.AttorneyQualityReviewTask\n(user)"]
0.RootTask --> 3.QualityReviewTask
3.QualityReviewTask --> 4.QualityReviewTask
4.QualityReviewTask --> 5.JudgeQualityReviewTask
5.JudgeQualityReviewTask --> 6.AttorneyQualityReviewTask
{{< /mermaid >}}

## Dispatch Phase
Background:
* [BVA Dispatch](https://github.com/department-of-veterans-affairs/caseflow/wiki/BVA-Dispatch)

Associated tasks:
* [BvaDispatchTask_Organization](task_descr/BvaDispatchTask_Organization.md)
  * [BvaDispatchTask_User](task_descr/BvaDispatchTask_User.md)
    * [JudgeDispatchReturnTask_User](task_descr/JudgeDispatchReturnTask_User.md) almost only in DR and ES dockets
      * [AttorneyDispatchReturnTask_User](task_descr/AttorneyDispatchReturnTask_User.md) only in DR and ES dockets

The following fake task tree merges several appeals to exemplify parent-child task relationships associated with the Quality Review phase
(Click on task links above to browse for task trees of actual appeals):

{{< mermaid >}}
flowchart TD
style 0.RootTask fill:#eeeeee
  0.RootTask(["0.RootTask\n(organization)"])
style 6.BvaDispatchTask fill:#b3de69
  6.BvaDispatchTask{{"6.BvaDispatchTask\n(organization)"}}
style 7.BvaDispatchTask fill:#b3de69
  7.BvaDispatchTask{{"7.BvaDispatchTask\n(user)"}}
style 8.JudgeDispatchReturnTask fill:#ffffb3
  8.JudgeDispatchReturnTask["8.JudgeDispatchReturnTask\n(user)"]
style 9.AttorneyDispatchReturnTask fill:#fccde5
  9.AttorneyDispatchReturnTask["9.AttorneyDispatchReturnTask\n(user)"]
style 10.OtherColocatedTask fill:#80b1d3
  10.OtherColocatedTask["10.OtherColocatedTask\n(organization)"]
style 11.OtherColocatedTask fill:#80b1d3
  11.OtherColocatedTask["11.OtherColocatedTask\n(user)"]
style 12.OtherColocatedTask fill:#80b1d3
  12.OtherColocatedTask["12.OtherColocatedTask\n(user)"]
0.RootTask --> 6.BvaDispatchTask
6.BvaDispatchTask --> 7.BvaDispatchTask
7.BvaDispatchTask --> 8.JudgeDispatchReturnTask
8.JudgeDispatchReturnTask --> 9.AttorneyDispatchReturnTask
9.AttorneyDispatchReturnTask --> 10.OtherColocatedTask
10.OtherColocatedTask --> 11.OtherColocatedTask
10.OtherColocatedTask --> 12.OtherColocatedTask
{{< /mermaid >}}

## MailTasks

A [mail task](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/tasks/mail_task.rb) is used to track when the mail team receives any appeal-related mail from an appellant.
* Mail is processed by a mail team member, and then a corresponding task is then assigned to an organization.
* Such tasks are assigned to organizations, including VLJ Support, AOD team, Privacy team, and Lit Support, and include:
  * add Evidence or Argument ([EvidenceOrArgumentMailTask_Organization](task_descr/EvidenceOrArgumentMailTask_Organization.md))
  * changing Power of Attorney (POA, [PowerOfAttorneyRelatedMailTask_Organization](task_descr/PowerOfAttorneyRelatedMailTask_Organization.md))
  * advance a case on docket (AOD = advance on docket, [AodMotionMailTask_Organization](task_descr/AodMotionMailTask_Organization.md))
  * withdrawing an appeal ([AppealWithdrawalMailTask_Organization](task_descr/AppealWithdrawalMailTask_Organization.md))
  * switching dockets ([DocketSwitchMailTask_Organization](task_descr/DocketSwitchMailTask_Organization.md))

Based on existing appeals, the following tasks can happen at any time after the DistributionTask and before the BvaDispatchTask:
* [EvidenceOrArgumentMailTask_Organization](task_descr/EvidenceOrArgumentMailTask_Organization.md)
  * [EvidenceOrArgumentMailTask_User](task_descr/EvidenceOrArgumentMailTask_User.md) only in DR and ES dockets

<details><summary>(Click left triangle to expand list of other MailTasks)</summary>

* [AodMotionMailTask_Organization](task_descr/AodMotionMailTask_Organization.md)
  * [AodMotionMailTask_User](task_descr/AodMotionMailTask_User.md)
* [HearingRelatedMailTask_Organization](task_descr/HearingRelatedMailTask_Organization.md)
  * [HearingRelatedMailTask_User](task_descr/HearingRelatedMailTask_User.md)
* [ReturnedUndeliverableCorrespondenceMailTask_Organization](task_descr/ReturnedUndeliverableCorrespondenceMailTask_Organization.md)
  * [ReturnedUndeliverableCorrespondenceMailTask_User](task_descr/ReturnedUndeliverableCorrespondenceMailTask_User.md)
* [PowerOfAttorneyRelatedMailTask_Organization](task_descr/PowerOfAttorneyRelatedMailTask_Organization.md) only in DR and ES dockets
  * [PowerOfAttorneyRelatedMailTask_User](task_descr/PowerOfAttorneyRelatedMailTask_User.md)
* [StatusInquiryMailTask_Organization](task_descr/StatusInquiryMailTask_Organization.md)
  * [StatusInquiryMailTask_User](task_descr/StatusInquiryMailTask_User.md)
* [CongressionalInterestMailTask_Organization](task_descr/CongressionalInterestMailTask_Organization.md)
  * [CongressionalInterestMailTask_User](task_descr/CongressionalInterestMailTask_User.md)
* [ExtensionRequestMailTask_Organization](task_descr/ExtensionRequestMailTask_Organization.md)
  * [ExtensionRequestMailTask_User](task_descr/ExtensionRequestMailTask_User.md)
* [FoiaRequestMailTask_Organization](task_descr/FoiaRequestMailTask_Organization.md)
  * [FoiaRequestMailTask_User](task_descr/FoiaRequestMailTask_User.md)
* [VacateMotionMailTask_Organization](task_descr/VacateMotionMailTask_Organization.md) only in DR and ES dockets
  * [VacateMotionMailTask_User](task_descr/VacateMotionMailTask_User.md)
* [OtherMotionMailTask_Organization](task_descr/OtherMotionMailTask_Organization.md)
  * [OtherMotionMailTask_User](task_descr/OtherMotionMailTask_User.md)
* [AddressChangeMailTask_Organization](task_descr/AddressChangeMailTask_Organization.md)
  * [AddressChangeMailTask_User](task_descr/AddressChangeMailTask_User.md)
* [ReconsiderationMotionMailTask_Organization](task_descr/ReconsiderationMotionMailTask_Organization.md)
  * [ReconsiderationMotionMailTask_User](task_descr/ReconsiderationMotionMailTask_User.md)
* [ControlledCorrespondenceMailTask_Organization](task_descr/ControlledCorrespondenceMailTask_Organization.md)
  * [ControlledCorrespondenceMailTask_User](task_descr/ControlledCorrespondenceMailTask_User.md)
* [DeathCertificateMailTask_Organization](task_descr/DeathCertificateMailTask_Organization.md)
  * [DeathCertificateMailTask_User](task_descr/DeathCertificateMailTask_User.md)
* [AppealWithdrawalMailTask_Organization](task_descr/AppealWithdrawalMailTask_Organization.md)
* [PrivacyActRequestMailTask_Organization](task_descr/PrivacyActRequestMailTask_Organization.md)
* [ClearAndUnmistakeableErrorMailTask_Organization](task_descr/ClearAndUnmistakeableErrorMailTask_Organization.md)
</details>


## Other Tasks
Background:
* [Litigation Support](https://github.com/department-of-veterans-affairs/caseflow/wiki/Litigation-Support) handles congressional inquiries, motions (pre- and post-decisional), CAVC remands, and responds to status inquiries on BVA cases. They are one of the last known teams who received a Queue and will work in Caseflow.

Other tasks:
* [TimedHoldTask_User](task_descr/TimedHoldTask_User.md)
* [Task_Organization](task_descr/Task_Organization.md)
  * [Task_User](task_descr/Task_User.md)
* [SpecialCaseMovementTask_User](task_descr/SpecialCaseMovementTask_User.md) - always has parent [DistributionTask_Organization](task_descr/DistributionTask_Organization.md)
* [BoardGrantEffectuationTask_Organization](task_descr/BoardGrantEffectuationTask_Organization.md)
* [PulacCerulloTask_Organization](task_descr/PulacCerulloTask_Organization.md)
  * [PulacCerulloTask_User](task_descr/PulacCerulloTask_User.md)


## Deprecated tasks
* [InformalHearingPresentationTask_Vso](InformalHearingPresentationTask_Vso.md) - IHP tasks assigned to VSO
* [GenericTask_Organization](task_descr/GenericTask_Organization.md)
  * [GenericTask_User](task_descr/GenericTask_User.md)
