class AttorneyLegacyTask < LegacyTask
  def available_actions(role)
    return [] if role != "attorney" || !task_id

    actions = [
      {
        label: COPY::ATTORNEY_CHECKOUT_DRAFT_DECISION_LABEL,
        value: "draft_decision/dispositions"
      },
      {
        label: COPY::ATTORNEY_CHECKOUT_OMO_LABEL,
        value: "omo_request/submit"
      }
    ]

    if FeatureToggle.enabled?(:attorney_assignment_to_colocated, user: assigned_to)
      actions.push(
        label: COPY::ATTORNEY_CHECKOUT_ADD_ADMIN_ACTION_LABEL,
        value: "colocated_task"
      )
    end

    actions
  end

  def self.from_vacols(case_assignment, appeal, user_id)
    super
  end
end
