| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# MailTask_Organization Description

The parent class to all mail tasks.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task to track when the mail team receives any appeal-related mail from an appellant.
* Mail is processed by a mail team member, and then a corresponding task is then assigned to an organization.
* Tasks are assigned to organizations, including VLJ Support, AOD team, Privacy team, and Lit Support, and include:
    - add Evidence or Argument
    - changing Power of Attorney
    - advance a case on docket (AOD)
    - withdrawing an appeal
    - switching dockets
    - add post-decision motions
* Adding a mail task to an appeal is done by mail team members and will create a task assigned to the mail team. It
  will also automatically create a child task assigned to the team the task should be routed to.
<!-- class_comments:end -->

These mappings are as follows:

Task type|Assignee
---|---
[AodMotionMailTask](AodMotionMailTask_Organization.md) | AodTeam
[AppealWithdrawalMailTask](AppealWithdrawalMailTask_Organization.md_Organization.md) | BvaIntake
[ClearAndUnmistakeableErrorMailTask](ClearAndUnmistakeableErrorMailTask_Organization.md_Organization.md) | LitigationSupport
[CongressionalInterestMailTask](CongressionalInterestMailTask_Organization.md_Organization.md) | LitigationSupport
[ControlledCorrespondenceMailTask](ControlledCorrespondenceMailTask_Organization.md_Organization.md) | LitigationSupport
[ReconsiderationMotionMailTask](ReconsiderationMotionMailTask_Organization.md) | LitigationSupport
[StatusInquiryMailTask](StatusInquiryMailTask_Organization.md) | LitigationSupport
[VacateMotionMailTask](VacateMotionMailTask_Organization.md) | LitigationSupport
[OtherMotionMailTask](OtherMotionMailTask_Organization.md) | LitigationSupport
[FoiaRequestMailTask](FoiaRequestMailTask_Organization.md) | PrivacyTeam
[PrivacyActRequestMailTask](PrivacyActRequestMailTask_Organization.md) | PrivacyTeam
[PrivacyComplaintMailTask](PrivacyComplaintMailTask_Organization.md) | PrivacyTeam
[DeathCertificateMailTask](DeathCertificateMailTask_Organization.md) | Colocated
[ExtensionRequestMailTask](ExtensionRequestMailTask_Organization.md) | Colocated
[EvidenceOrArgumentMailTask](EvidenceOrArgumentMailTask_Organization.md) | MailTeam (if the case is active) <br> Colocated (otherwise)
[AddressChangeMailTask](AddressChangeMailTask_Organization.md) | HearingAdmin (if there is a pending hearing) <br> Colocated (otherwise)
[HearingRelatedMailTask](HearingRelatedMailTask_Organization.md) | HearingAdmin (if there is a pending hearing) <br> Colocated (otherwise)
[PowerOfAttorneyRelatedMailTask](PowerOfAttorneyRelatedMailTask_Organization.md) | HearingAdmin (if there is a pending hearing) <br> Colocated (otherwise)
[ReturnedUndeliverableCorrespondenceMailTask](ReturnedUndeliverableCorrespondenceMailTask_Organization.md) | HearingAdmin (if there is a pending hearing) <br> BvaDispatch (if the case is no longer active) <br> The assignee of the most recent task (otherwise)
