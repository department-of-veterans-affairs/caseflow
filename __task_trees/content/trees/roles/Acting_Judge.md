| [All Roles][ar] | [Attorney][a] | [Judge][j] | [Colocated][c] | [Acting Judge][aj] | [Dispatch User][du] | [Regional Office User][ro] | [Intake User][iu] | [Hearings User][hu] |

# Acting Judge Description

In Queue the Acting Judge role is for users performing the duties of an AVLJ within the Veteran appeals process. The Acting Judge role is similar to the judge role, however they are limited by:

**Lack of a Judge Team**

- Where a true VLJ could choose an attorney on their team or any attorney when assigning or reassigning an AMA drafting task, AVLJ must to choose from a list of all attorneys
- When a true VLJ user could assign a redrafting Dispatch Return or [Quality Review](../task_descr/QualityReviewTask_Organization.md) task to any attorney on their team, AVLJ can only return to the drafting attorney.

**Acting as Attorney while AVLJ**

- VLJs cannot assign Legacy cases to the AVLJ user to draft
- AVLJs are still listed as assignable attorneys
- For Legacy appeals with VLJ Support tasks, the message to complete an admin action always calls the AVLJ a judge, even if they assigned the task in the capability as a drafting attorney

This is not intended behavior and there is a bug to address this [issue](https://github.com/department-of-veterans-affairs/caseflow/issues/13136)

**Other**

- Acting VLJ have no queue list of legacy cases with an JudgeLegacyAssignTask assigned to them
- Acting Judges cannot act on JudgeLegacyAssignTask assigned to them, even if they navigate directly to the case

This is not intended behavior and there is a bug to address this [issue](https://github.com/department-of-veterans-affairs/caseflow/issues/13136)

## Tasks

See [Judge Tasks](Judge.md)
See [Attorney Tasks](Attorney.md)

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
