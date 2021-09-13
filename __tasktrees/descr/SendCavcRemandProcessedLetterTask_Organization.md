| [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |
# SendCavcRemandProcessedLetterTask_Organization Description

Task stats [for DR](../docs-DR/SendCavcRemandProcessedLetterTask_Organization.md), [for ES](../docs-ES/SendCavcRemandProcessedLetterTask_Organization.md), [for H](../docs-H/SendCavcRemandProcessedLetterTask_Organization.md) dockets.


<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task for Litigation Support to take necessary action before sending the CAVC-remand-processed letter to an appellant.
* This task is for CAVC Remand appeal streams.
* If this task is assigned to an org (i.e., CavcLitigationSupport), then:
- Expected parent: CavcTask
- Expected assigned_to: CavcLitigationSupport
* If this task is assigned to a user (i.e., a member of CavcLitigationSupport), then:
- Expected parent: SendCavcRemandProcessedLetterTask that is assigned to CavcLitigationSupport
- Expected assigned_to.type: User
  
* CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands
<!-- class_comments:end -->
