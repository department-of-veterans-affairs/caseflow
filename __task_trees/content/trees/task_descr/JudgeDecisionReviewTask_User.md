| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# JudgeDecisionReviewTask_User Description

Task stats [for DR](../docket-DR/JudgeDecisionReviewTask_User.md), [for ES](../docket-ES/JudgeDecisionReviewTask_User.md), [for H](../docket-H/JudgeDecisionReviewTask_User.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task for a judge to review decisions.
* A JudgeDecisionReviewTask implies that there is a decision that needs to be reviewed from an attorney.
* The case associated with this task appears in the judge's Cases to review view
* There should only ever be one open JudgeDecisionReviewTask at a time for an appeal.
* If an AttorneyTask is cancelled, we would want to cancel both it and its parent JudgeDecisionReviewTask
  and create a new JudgeAssignTask, because another assignment by a judge is needed.
<!-- class_comments:end -->
