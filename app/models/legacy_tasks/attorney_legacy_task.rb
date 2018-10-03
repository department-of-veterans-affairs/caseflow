class AttorneyLegacyTask < LegacyTask
  def allowed_actions(role)
    return [] if role != "attorney"

    actions = [
      {
        label: "Decision Ready for Review",
        value: "draft_decision/dispositions"
      },
      {
        label: "Medical Request Ready for Review",
        value: "omo_request/submit"
      }
    ]

    if FeatureToggle.enabled?(:attorney_assignment_to_colocated, user: assigned_to)
      actions.push(label: "Add admin action", value: "colocated_task")
    end

    actions
  end
end
