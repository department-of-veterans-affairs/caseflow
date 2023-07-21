# frozen_string_literal: true

class AttorneyLegacyTask < LegacyTask
  def available_actions(current_user, role)
    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table. task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.
    return [] unless task_id

    if current_user&.can_act_on_behalf_of_judges? &&
       (appeal.case_record.reload.bfcurloc == "57" || appeal.case_record.reload.bfcurloc == "CASEFLOW")
      [
        Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT_LEGACY.to_h
      ]
    else
      if current_user&.judge_in_vacols? || current_user&.can_act_on_behalf_of_judges?
        [
          Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
          Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h
        ] elsif current_user&.attorney? || role == "attorney"
            [
              Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
              Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h,
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h
            ]
      else
        []
      end
    end
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def label
    return false if appeal.case_record.nil?

    if appeal.case_record.reload.bfcurloc == "57" || appeal.case_record.reload.bfcurloc == "CASEFLOW"
      COPY::ATTORNEY_REWRITE_TASK_LEGACY_LABEL
    else
      COPY::ATTORNEY_REWRITE_TASK_LABEL
    end
  end
end
