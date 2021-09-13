| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

# RootTask_Organization Description

Task stats [for DR](../docket-DR/RootTask_Organization.md), [for ES](../docket-ES/RootTask_Organization.md), [for H](../docket-H/RootTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Caseflow Intake establishes the appeal. Once the appeal is established, Caseflow Queue automatically
  creates a Root Task for other tasks to attach to, depending on the Veteran's situation.
* Root task that tracks an appeal all the way through the appeal lifecycle.
* This task is closed when an appeal has been completely resolved.
* There should only be one RootTask per appeal.
<!-- class_comments:end -->
