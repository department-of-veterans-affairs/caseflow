| [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |
# ChangeHearingRequestTypeTask_User Description

Task stats [for DR](../docs-DR/ChangeHearingRequestTypeTask_User.md), [for ES](../docs-ES/ChangeHearingRequestTypeTask_User.md), [for H](../docs-H/ChangeHearingRequestTypeTask_User.md) dockets.


<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task created when a hearing coordinator visits the Case Details page of an appeal with a
* Travel Board hearing request. Gives the user the option to convert that request to a video
  or virtual hearing request so it can be scheduled in Caseflow.
  
* When task is completed, i.e the field `changed_hearing_request_type` is passed as payload, the location
  of LegacyAppeal is moved `CASEFLOW` and the parent `ScheduleHearingTask` is set to be `assigned`
<!-- class_comments:end -->
