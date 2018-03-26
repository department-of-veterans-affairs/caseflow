class AttorneyVacolsAssignment < VacolsAssignment
  def self.from_vacols(case_assignment, user_id)
    task = super
    if case_assignment.assigned_to_attorney_date
      task.task_id = case_assignment.vacols_id + "-" + case_assignment.assigned_to_attorney_date.strftime("%Y-%m-%d")
    end
    task.assigned_on = case_assignment.assigned_to_attorney_date
    task
  end
end

