module Constants::TaskActionList
  ACCESS_CONTROL = [
    {
      task_type: ["AttorneyTask"],
      available_actions:
        [
          {
            label: "Decision Ready for Review",
            value: "draft_decision/special_issues"
          },
          {
            label: "Add admin action",
            value: "colocated_task"
          }
        ]
    }
  ]

  LEGACY_ACCESS_CONTROL = [
    {
      vacols_role: ["attorney"],
      available_actions:
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
        ]
    }
  ]
end