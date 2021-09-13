| [All Roles][ar] | [Attorney][a] | [Judge][j] | [Colocated][c] | [Acting Judge][aj] | [Dispatch User][du] | [Regional Office User][ro] | [Intake User][iu] | [Hearings User][hu] |

# Hearings User Description

Hearings users encompass any users of the caseflow application that are involved with scheduling and managing hearings within the Veteran appeals process. This can include [Acting Judge](Acting_Judge.md), [Attorney](Attorney.md), [Judge](Judge.md), and [Colocated](Colocated.md) users.

Additionally, there are 2 users specific to the hearings phase:

- Hearing Coordinator
- Hearing Coordinator (admin)

Hearing coordinators have the ability to schedule hearings on behalf of veterans, while hearing coordinator admins have the ability to build a hearing schedule based on the judge and regional office availability.

## Tasks

- [Hearing Task](../task_descr/HearingTask_Organization.md)
- [Schedule Hearing Task](../task_descr/ScheduleHearingTask_Organization.md)
- [Hearing Admin Action Task](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/tasks/hearing_admin_action_task.rb)
- [Hearing Admin Action Verify Address Task (Organization)](../task_descr/HearingAdminActionVerifyAddressTask_Organization.md)
  - [Hearing Admin Action Verify Address Task (User)](../task_descr/HearingAdminActionVerifyAddressTask_User.md)
- [Hearing Admin Action Other Task (Organization)](../task_descr/HearingAdminActionOtherTask_Organization.md)
  - [Hearing Admin Action Other Tasks (User)](../task_descr/HearingAdminActionOtherTask_User.md)
- [Hearing Admin Action Foreign Veteran Case Task](../task_descr/HearingAdminActionForeignVeteranCaseTask_Organization.md)
- [Hearing Admin Action Foia Privacy Request Task (Organization)](../task_descr/HearingAdminActionFoiaPrivacyRequestTask_Organization.md)
  - [Hearing Admin Action Foia Privacy Request Task (User)](../task_descr/HearingAdminActionFoiaPrivacyRequestTask_User.md)
- [Assign Hearing Disposition Task](../task_descr/AssignHearingDispositionTask_Organization.md)
- [Change Hearing Disposition Task](../task_descr/ChangeHearingDispositionTask_Organization.md)
- [No-Show Hearing Task (Organization)](../task_descr/NoShowHearingTask_Organization.md)
  - [No-Show Hearing Task (User)](../task_descr/NoShowHearingTask_User.md)
- [Timed Hold Task](../task_descr/TimedHoldTask_Organization.md)
- [Transcription Task](../task_descr/TranscriptionTask_Organization.md)
- [Missing Hearing Transcripts Colocated Task](../task_descr/MissingHearingTranscriptsColocatedTask_Organization.md)

[ar]: ./role-overview.md
[ro]: ./Regional_Office_User.md
[aj]: ./Acting_Judge.md
[a]: ./Attorney.md
[hu]: ./Hearings_User.md
[iu]: ./Intake_User.md
[du]: ./Dispatch_User.md
[c]: ./Colocated.md
[j]: ./Judge.md
[vsoe]: ./VSO_Employee.md
