| [All Roles][ar] | [Attorney][a] | [Judge][j] | [Colocated][c] | [Acting Judge][aj] | [Dispatch User][du] | [Regional Office User][ro] | [Intake User][iu] | [Hearings User][hu] |

# Intake User Description

Intake users encompass any user of Caseflow that can perform intake tasks within the Veteran appeals process.

## Tasks

**NOTE:** Intake users do not have any assigned tasks within Caseflow as a case is not "in" caseflow until a user has completed intake. Once they intake a case into caseflow, then any of the tasks listed below are created, but not to be acted upon by an intake user.

(see [`Appeal#create_tasks_on_intake_success!`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/appeal.rb#L336)):

- [Track Veteran Task](../task_descr/TrackVeteranTask_Organization.md)
- [Evidence Submission Window Task](../task_descr/EvidenceSubmissionWindowTask_Organization.md)
- [Schedule Hearing Task](../task_descr/ScheduleHearingTask_Organization.md)
- [Informal Hearing Presentation Task](../task_descr/InformalHearingPresentationTask_Organization.md)
- [Informal Hearing Presentation Task](../task_descr/InformalHearingPresentationTask_User.md)
- [Translation Task (Organization)](../task_descr/TranslationTask_Organization.md)
  - [Translation Task (User)](../task_descr/TranslationTask_User.md)
- [Veteran Record Request](../task_descr/VeteranRecordRequest_Organization.md)

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
