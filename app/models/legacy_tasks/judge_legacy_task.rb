class JudgeLegacyTask < LegacyTask

  def no_actions_available?(role)
    role != "judge"
  end

  def self.from_vacols(record, appeal, user_id)
    super.merge(work_product: record.work_product)
  end
end

class JudgeLegacyTaskFactory
  def self.from_vacols(record, appeal, user_id)
    obj = record.reassigned_to_judge_date.present? ? ReviewJudgeLegacyTask : AssignJudgeLegacyTask
    obj.from_vacols(record, appeal, user_id)
  end
end

class AssignJudgeLegacyTask < JudgeLegacyTask
  def action
    "assign"
  end

  def available_actions(role)
    return [] if no_actions_available?(role)
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
  end
end

class ReviewJudgeLegacyTask < JudgeLegacyTask
  def action
    "review"
  end

  def available_actions(role)
    return [] if no_actions_available?(role)
    if Constants::DECASS_WORK_PRODUCT_TYPES["OMO_REQUEST"].include?(work_product)
      [{
        label: COPY::JUDGE_CHECKOUT_OMO_LABEL,
        value: "omo_request/evaluate"
      }]
    else
      [{
        label: COPY::JUDGE_CHECKOUT_DISPATCH_LABEL,
        value: "dispatch_decision/dispositions"
      }]
    end
  end

  def self.from_vacols(record, appeal, user_id)
    super.merge(previous_task: LegacyTask.new(assigned_at: record.assigned_to_attorney_date.try(:to_date)))
  end
end
