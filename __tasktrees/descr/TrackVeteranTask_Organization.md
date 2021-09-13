| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# TrackVeteranTask_Organization Description

Task stats [for DR](../docs-DR/TrackVeteranTask_Organization.md), [for ES](../docs-ES/TrackVeteranTask_Organization.md), [for H](../docs-H/TrackVeteranTask_Organization.md) dockets.

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task created for appellant representatives to track appeals that have been received by the Board.
  
* After the appeal is established, if the Veteran has a representative, a Track Veteran Task is automatically
  created and assigned to that representative so they can see their appeals. This could be an: IHP-writing VSO,
  field VSO, private attorney, or agent.
    - If the Veteran has an IHP-writing VSO as their representative, an InformalHearingPresentationTask
      is also automatically created and assigned.
  
* Private attorneys, agents, and field VSOs cannot create, assign, or be assigned any tasks
  (other than the TrackVeteranTask, which does not require action).
  
* Assigning this task to the representative results in the associated case appearing in their view in Caseflow.
* Created either when:
    - a RootTask is created for an appeal represented by a VSO
    - the power of attorney changes on an appeal
  
* See `Appeal#create_tasks_on_intake_success!` and `InitialTasksFactory.create_root_and_sub_tasks!`.
<!-- class_comments:end -->

Related tickets:
* [Prevent creation of duplicate TrackVeteranTasks](https://github.com/department-of-veterans-affairs/caseflow/issues/10824)
