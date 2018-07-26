class JudgeLegacyTask < LegacyTask
  def self.from_vacols(record, appeal, user_id)
    task = super
    task.type = record.reassigned_to_judge_date.present? ? "Review" : "Assign"
    task.assigned_at = record.reassigned_to_judge_date || record.assigned_to_location_date
    # If task type is 'assign' that means there was no previous task record yet
    task.previous_task = LegacyTask.new(assigned_at: record.assigned_to_attorney_date) if task.type == "Review"
    task.work_product = record.work_product
    task
  end
end
