| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |

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
    - postponing a hearing
    - withdrawing a hearing
* Adding a mail task to an appeal is done by mail team members and will create a task assigned to the mail team. It
  will also automatically create a child task assigned to the team the task should be routed to.
<!-- class_comments:end -->

These mappings are as follows:

Task type|Assignee
