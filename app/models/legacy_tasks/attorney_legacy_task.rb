class AttorneyLegacyTask < LegacyTask
  def available_actions(current_user, role)
    return [] if role != "attorney" || current_user != assigned_to

    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table. task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.
    return [] unless task_id

    actions = [Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
               Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h]

    if FeatureToggle.enabled?(:attorney_assignment_to_colocated, user: assigned_to)
      actions.push(Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h)
    end

    actions
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def self.from_vacols(case_assignment, appeal, user_id)
    super
  end
end
