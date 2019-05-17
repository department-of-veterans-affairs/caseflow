# frozen_string_literal: true

class JudgeLegacyTask < LegacyTask
  def review_action
    if Constants::DECASS_WORK_PRODUCT_TYPES["OMO_REQUEST"].include?(work_product)
      Constants.TASK_ACTIONS.ASSIGN_OMO.to_h
    else
      Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
    end
  end

  def available_actions(current_user, role)
    return [] if role != "judge" || current_user != assigned_to

    action_label = if action.eql?(COPY::JUDGE_DECISION_REVIEW_TASK_LABEL)
                     review_action
                   else
                     Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
                   end
    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      action_label
    ]
  end

  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def self.from_vacols(record, appeal, user_id)
    task = super

    task.action = if record.reassigned_to_judge_date.present?
                    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
                  else
                    COPY::JUDGE_ASSIGN_TASK_LABEL
                  end

    if task.action == COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
      # If task action is 'assign' that means there was no previous task record yet
      task.previous_task = LegacyTask.new(assigned_at: record.assigned_to_attorney_date.try(:to_date))
    end
    task.work_product = record.work_product
    task
  end
end
