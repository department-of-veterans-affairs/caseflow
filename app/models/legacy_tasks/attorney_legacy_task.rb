class AttorneyLegacyTask < LegacyTask
  def allowed_actions(role)
    return [] if role != "attorney"

    [
      {
        label: "Decision Ready for Review",
        value: "draft_decision/dispositions"
      },
      {
        label: "Medical Request Ready for Review",
        value: "omo_request/submit"
      },
      {
        label: "Add admin action",
        value: "colocated_task"
      }
    ]
  end

  def self.from_vacols(case_assignment, appeal, user_id)
    super
  end
end
