| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |
# MandateHoldTask_Organization Description

Task stats [for DR](../docket-DR/MandateHoldTask_Organization.md), [for ES](../docket-ES/MandateHoldTask_Organization.md), [for H](../docket-H/MandateHoldTask_Organization.md) dockets.


<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task to indicate that CAVC Litigation Support is waiting on a mandate from the Board
  for a CAVC remand of type straight_reversal or death_dismissal.
* The appeal is being remanded, but CAVC has not returned the mandate to the Board yet.
* When this task is created, it is automatically placed on hold for 90 days to wait for CAVC's mandate.
* There is an option of ending the hold early.
* This task is only for CAVC Remand appeal streams.
  
* Expected parent: CavcTask
* Expected assigned_to.type: CavcLitigationSupport
  
* CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands
<!-- class_comments:end -->
