| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# TimedHoldTask_Organization Description

Task stats [for DR](../docs-DR/TimedHoldTask_Organization.md), [for ES](../docs-ES/TimedHoldTask_Organization.md), [for H](../docs-H/TimedHoldTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task that places parent task on hold for specified length of time. Holds expire through the TaskTimerJob.
  https://github.com/department-of-veterans-affairs/caseflow/wiki/Timed-Tasks#timedholdtask
<!-- class_comments:end -->

TimedHoldTask_Organization is used only for appeals in the Hearing docket -- see [All Tasks](../alltasks.md).

See [TimedHoldTask_User](TimedHoldTask_User.md), which is used for all dockets.

