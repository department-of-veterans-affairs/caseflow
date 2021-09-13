| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# JudgeAssignTask_User Description

Task stats [for DR](../docs-DR/JudgeAssignTask_User.md), [for ES](../docs-ES/JudgeAssignTask_User.md), [for H](../docs-H/JudgeAssignTask_User.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task assigned to judge from which they will assign the associated appeal to one of their attorneys by creating a
  task (an AttorneyTask but not any of its subclasses) to draft a decision on the appeal.
* Task is created as a result of case distribution.
* Task should always have a RootTask as its parent.
* Task can one or more AttorneyTask children, one or more ColocatedTask children, or no child tasks at all.
* An open task will result in the case appearing in the Judge Assign View.
  
* Expected parent task: RootTask
  
* Expected child task: JudgeAssignTask can have one or more ColocatedTask children or no child tasks at all.
* Historically, it can have AttorneyTask children, but AttorneyTasks should now be under JudgeDecisionReviewTasks.
<!-- class_comments:end -->

See [possible children tasks for DR docket](../docs-DR/JudgeAssignTask_User.md#parent-and-child-tasks).

## When is this task created?
These scenarios trigger creation of this task:
1. [When a case](https://github.com/department-of-veterans-affairs/caseflow/blob/ee0e4dda256fa75de113109644605e07dee1a722/app/models/docket.rb#L42) is [distributed](https://github.com/department-of-veterans-affairs/caseflow/blob/ee0e4dda256fa75de113109644605e07dee1a722/app/models/docket.rb#L75) the [DistributionTask](DistributionTask_Organization.md)) is closed and a `JudgeAssignTask` is created.
2. [When an `AttorneyTask` is cancelled](https://github.com/department-of-veterans-affairs/caseflow/blob/ee0e4dda256fa75de113109644605e07dee1a722/app/models/tasks/attorney_task.rb#L17) the `JudgeDecisionReviewTask` is also cancelled and a new `JudgeAssignTask` is created.
3. [During special case movement](https://github.com/department-of-veterans-affairs/caseflow/blob/ee0e4dda256fa75de113109644605e07dee1a722/app/models/tasks/special_case_movement_task.rb#L15) we skip to the front of the line of cases waiting to be assigned to judges by closing the `DistributionTask` and creating a `JudgeAssignTask`

