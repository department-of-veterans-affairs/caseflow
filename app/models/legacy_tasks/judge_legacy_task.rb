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

      # sets previous_task.assigned_on to the first time the case was sent to the attorney
      # or the associated decass value if a priorloc doesn't exist
      assigned_at_time =
        appeal.location_history
          .filter(&:with_attorney?)
          .filter { |loc| loc.locdout.to_date == record.assigned_to_attorney_date.to_date }
          .first&.locdout.try(:to_datetime) || record.assigned_to_attorney_date.try(:to_datetime)

      JudgeLegacyDecisionReviewTask.new(
        task.instance_values.merge("previous_task" => LegacyTask.new(assigned_at: assigned_at_time))
      )
    else
      JudgeLegacyAssignTask.new(task.instance_values)
    end
  end
end
