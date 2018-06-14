class JudgeCaseAssignmentToAttorney
  include ActiveModel::Model
  include LegacyTaskConcern

  attr_accessor :appeal_id, :assigned_to, :task_id, :assigned_by, :type

  validates :assigned_by, :assigned_to, presence: true
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

  private

  def vacols_id
    super || LegacyAppeal.find(appeal_id).vacols_id
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && assigned_by.vacols_role != "Judge"
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
