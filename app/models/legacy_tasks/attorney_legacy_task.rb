# frozen_string_literal: true

class AttorneyLegacyTask < LegacyTask
  def available_actions(current_user, role)
    return [] if role != "attorney" || current_user != assigned_to

    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table. task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.
    return [] unless task_id

    actions = [Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
               Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h,
               Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h]

    if SpecialCaseMovementTeam.singleton.user_has_access?(current_user) &&
       legacy_atty_to_atty_special_case_movement(current_user)
      actions << Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    end

    actions
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def label
    COPY::ATTORNEY_TASK_LABEL
  end

  def legacy_atty_to_atty_special_case_movement(user)
    FeatureToggle.enabled?(:legacy_case_movement_atty_to_atty_for_decisiondraft, user: user) && appeal.is_a?(LegacyAppeal)
  end
end
