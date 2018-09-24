module Constants::TaskActionList
  ACCESS_CONTROL = [
    {
      role: "VSO",
      feature_toggle: "vso_queue_toggle",
      vacols_role: "vso user",
      task_type: "VSO",
      actions:
        [
          {
            label: "Complete Task",
            value: "complete"
          }
        ],
      endpoints: ["task/complete"]
    },
    {
      is_legacy: false,
      task_type: "AttorneyTask",
      actions:
        [
          {
            label: "Decision Ready for Review",
            value: "draft_decision/special_issues"
          },
          {
            label: "Add admin action",
            value: "colocated_task"
          }
        ],
      endpoints: ["task/complete"]
    },
    {
      is_legacy: true,
      vacols_role: ["attorney"],
      actions:
        [
          {
            label: "Medical Request Ready for Review",
            value: "omo_request/submit"
          },
          {
            label: "Decision Ready for Review",
            value: "draft_decision/dispositions"
          },
          {
            label: "Add admin action",
            value: "colocated_task"
          }
        ],
      endpoints: ["task/complete"]
    },
    {
      is_legacy: false,
      task_type: "JudgeTask",
      actions:
        [
          {
            label: "Ready for Dispatch",
            value: "dispatch_decision/special_issues"
          }
        ],
      endpoints: ["task/complete"]
    },
    {
      is_legacy: true,
      vacols_role: ["judge"],
      actions:
        [
          {
            label: "Assign OMO",
            value: "assign_omo_request"
          },
          {
            label: "Ready for Dispatch",
            value: "dispatch_decision/dispositions"
          }
        ],
      endpoints: ["task/complete"]
    },
    {
      is_legacy: false,
      task_type: "GenericTask",
      actions:
        [
          {
            label: "Complete Task",
            value: "complete"
          },
          {
            label: "Assign Task to Team",
            value: "assign"
          },
          {
            label: "Assign Task to Person",
            value: "assign_to_person"
          }
        ],
      endpoints: ["task/complete"]
    }
  ]
end