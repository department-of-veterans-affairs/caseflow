| [All Roles][ar] | [Attorney][a] | [Judge][j] | [Colocated][c] | [Acting Judge][aj] | [Dispatch User][du] | [Regional Office User][ro] | [Intake User][iu] | [Hearings User][hu] |

# Judge Description

The Judge role is for users of the Caseflow application performing the duties of a Judge in the Veteran appeals process. The Judge is primarily responsible for assigning tasks to attorneys as well as reviewing appeals decisions. Other responsibilities of the judge role include hearing related tasks including the [Schedule Hearing](docket-H/ScheduleHearingColocatedTask_Organization.md) and the [Hearing Clarification](docket-H/HearingClarificationColocatedTask_Organization.md) tasks.

## Tasks

There is are 2 main tasks that a user with the Judge role will be assigned and able to complete:

- [Judge Assign Task](../task_descr/JudgeAssignTask_User.md)
- [Judge Decision Review Task](../task_descr/JudgeDecisionReviewTask_User.md)

The [Judge Assign Task](../task_descr/JudgeAssignTask_User.md) is created by a [Distribution Task](../task_descr/DistributionTask_Organization.md) when a Judge requests more cases. The Judge then has the ability to assign the case to an Attorney which will create an [Attorney Task](../task_descr/AttorneyTask_User.md). Once the attorney task has been created, there will be additional child tasks associated with the attorney task that can be completed by users with the [Attorney](./Attorney.md) role.

After a child [Attorney Task](../task_descr/AttorneyTask_User.md) is completed by the attorney, the parent [Judge Decision Review Task](../task_descr/JudgeDecisionReviewTask_User.md) (which is assigned to the judge) becomes active, at which point the judge can then complete that task.

In addition to the attorney task, there are many other tasks that can be created as a result of the judge assign task. For a more comprehensive list and workflow see the [Judge Assign Task Tree](../docket-H/JudgeAssignTask_User.md)

**Additional**

- [Judge Dispatch Return Task](../task_descr/JudgeDispatchReturnTask_User.md)
- [Judge Quality Review Task](../task_descr/JudgeQualityReviewTask_User.md)

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
