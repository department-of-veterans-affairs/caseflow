| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |
# ChangeHearingRequestTypeTask_User Description

Task stats [for DR](../docket-DR/ChangeHearingRequestTypeTask_User.md), [for ES](../docket-ES/ChangeHearingRequestTypeTask_User.md), [for H](../docket-H/ChangeHearingRequestTypeTask_User.md) dockets.


<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task created when a hearing coordinator visits the Case Details page of an appeal with a
* Travel Board hearing request. Gives the user the option to convert that request to a video
  or virtual hearing request so it can be scheduled in Caseflow.
  
* When task is completed, i.e the field `changed_hearing_request_type` is passed as payload, the location
  of LegacyAppeal is moved `CASEFLOW` and the parent `ScheduleHearingTask` is set to be `assigned`
<!-- class_comments:end -->
