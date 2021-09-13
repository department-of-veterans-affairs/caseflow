| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |
# CavcRemandProcessedLetterResponseWindowTask_Organization Description

Task stats [for DR](../docket-DR/CavcRemandProcessedLetterResponseWindowTask_Organization.md), [for ES](../docket-ES/CavcRemandProcessedLetterResponseWindowTask_Organization.md), [for H](../docket-H/CavcRemandProcessedLetterResponseWindowTask_Organization.md) dockets.


<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task to indicate that Litigation Support is awaiting a response from the appellant,
  after sending the CAVC-remand-processed letter to an appellant (SendCavcRemandProcessedLetterTask).
* This task is for CAVC Remand appeal streams.
* The appeal is put on hold for 90 days, with the option of ending the hold early.
* After 90 days, the task comes off hold and show up in the CavcLitigationSupport team's unassigned tab
  to be assigned and acted upon.
* While on-hold, a CAVC Litigation Support user has the ability to add actions in response to Veterans replying
  before the 90-day window is complete. If they end the hold, they can put the task back on hold.
* Users cannot mark task complete without ending the hold.
  
* Expected parent: CavcTask
* Expected assigned_to.type: CavcLitigationSupport
  
* CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands
<!-- class_comments:end -->
