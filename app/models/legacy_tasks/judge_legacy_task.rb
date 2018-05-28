class JudgeLegacyTask < LegacyTask
  def self.from_vacols(case_assignment, user_id)
    task = super
    task.type = case_assignment.reassigned_to_judge_date.present? ? "Review" : "Assign"
    task.assigned_at = case_assignment.reassigned_to_judge_date || case_assignment.assigned_to_location_date
    task
  end
end
