class AttorneyLegacyTask < LegacyTask
  def self.from_vacols(case_assignment, appeal, user_id)
    task = super
    task.assigned_at = case_assignment.assigned_to_attorney_date.try(:to_date)
    task
  end
end
