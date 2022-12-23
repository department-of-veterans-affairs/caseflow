# frozen_string_literal: true

class JudgeLegacyTask < LegacyTask
  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def self.from_vacols(record, appeal, user_id)
    task = super

    task.work_product = record.work_product

    if record.reassigned_to_judge_date.present?
      # If task action is 'assign' that means there was no previous task record yet
      JudgeLegacyDecisionReviewTask.new(
        task.instance_values.merge(
          "previous_task" => LegacyTask.new(assigned_at: record.assigned_to_attorney_date.try(:to_datetime))
        )
      )
    else
      JudgeLegacyAssignTask.new(task.instance_values)
    end
  end
end
