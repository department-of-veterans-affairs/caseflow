class JudgeVacolsAssignment < VacolsAssignment
  def self.from_vacols(case_assignment, user_id)
    task = super
    if case_assignment.date_added
      task.task_id = case_assignment.vacols_id + "-" + case_assignment.date_added.strftime("%Y-%m-%d")
    end
    task.task_type = case_assignment.reassigned_to_judge_date.present? ? "Review" : "Assign"
    task.assigned_on = case_assignment.reassigned_to_judge_date || case_assignment.date_added
    task
  end
end