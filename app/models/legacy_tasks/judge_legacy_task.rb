class JudgeLegacyTask < LegacyTask
  def review_action
    if Constants::DECASS_WORK_PRODUCT_TYPES["OMO_REQUEST"].include?(work_product)
      Constants.TASK_ACTIONS.ASSIGN_OMO.to_h
    else
      Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h
    end
  end

  def available_actions(role)
    return [] if role != "judge"

    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      action.eql?("review") ? review_action : Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    ]
  end

  def self.from_vacols(record, appeal, user_id)
    task = super
    task.action = record.reassigned_to_judge_date.present? ? "review" : "assign"
    if task.action == "review"
      # If task action is 'assign' that means there was no previous task record yet
      task.previous_task = LegacyTask.new(assigned_at: record.assigned_to_attorney_date.try(:to_date))
    end
    task.work_product = record.work_product
    task
  end
end
