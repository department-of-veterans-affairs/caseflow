class JudgeCaseAssignmentToAttorney
  include ActiveModel::Model

  attr_accessor :appeal_id, :assigned_to, :task_id, :assigned_by

  validates :assigned_by, :assigned_to, presence: true
  validates :task_id, format: { with: /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  validate :assigned_by_role_is_valid

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

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end

  def vacols_id
    vacols_id_from_task_id || LegacyAppeal.find(appeal_id).vacols_id
  end

  def last_case_assignment
    VACOLS::CaseAssignment.select_tasks.where("brieff.bfkey = ?", vacols_id).sort_by(&:created_at).last
  end

  private

  def vacols_id_from_task_id
    task_id.split("-", 2).first if task_id
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && !assigned_by.judge_in_vacols?
  end

  class << self
    attr_writer :repository

    def create(task_attrs)
      task = new(task_attrs)
      task.assign_to_attorney! if task.valid?
      task
    end

    def update(task_attrs)
      task = new(task_attrs)
      task.reassign_to_attorney! if task.valid?
      task
    end

    def repository
      return QueueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= QueueRepository
    end
  end
end
