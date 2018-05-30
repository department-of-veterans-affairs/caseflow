class AttorneyLegacyTask < LegacyTask
  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  validates :assigned_by, :assigned_to, presence: true
  validate :assigned_by_role_is_valid

  def self.from_vacols(case_assignment, user_id)
    task = super
    task.assigned_at = case_assignment.assigned_to_attorney_date
    task
  end

  def self.create(task_attrs)
    task = new(task_attrs)
    task.assign_to_attorney! if task.valid?
    task
  end

  def self.update(task_attrs)
    task = new(task_attrs)
    task.reassign_to_attorney! if task.valid?
    task
  end

  def assign_to_attorney!
    MetricsService.record("VACOLS: assign_case_to_attorney #{vacols_id}",
                          service: :vacols,
                          name: "assign_case_to_attorney") do
      self.class.repository.assign_case_to_attorney!(
        judge: assigned_by,
        attorney: assigned_to,
        vacols_id: vacols_id
      )
    end
  end

  def reassign_to_attorney!
    MetricsService.record("VACOLS: reassign_case_to_attorney #{vacols_id}",
                          service: :vacols,
                          name: "reassign_case_to_attorney") do
      self.class.repository.reassign_case_to_attorney!(
        judge: assigned_by,
        attorney: assigned_to,
        vacols_id: vacols_id,
        created_in_vacols_date: created_in_vacols_date
      )
    end
  end

  private

  def vacols_id
    task_id ? task_id.split("-", 2).first : appeal_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && assigned_by.vacols_role != "Judge"
  end
end
