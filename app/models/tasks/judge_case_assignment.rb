# TODO: inherit from Task
class JudgeCaseAssignment
  include ActiveModel::Model

  attr_accessor :task_id, :assigned_by, :assigned_to, :appeal_id, :appeal_type, :type

  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  validates :appeal_type, inclusion: { in: %w[Legacy Ama] }
  validates :assigned_by, :assigned_to, presence: true
  validate :assigned_by_role_is_valid

  def assign_to_attorney!
    case appeal_type
    when "Legacy"
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
  end

  def reassign_to_attorney!
    case appeal_type
    when "Legacy"
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
  end

  private

  def vacols_id
    task_id ? task_id.split("-", 2).first : LegacyAppeal.find(appeal_id).vacols_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && assigned_by.vacols_role != "Judge"
  end

  class << self
    attr_writer :repository

    def create(task_attrs)
      task = JudgeCaseAssignment.new(task_attrs)
      task.assign_to_attorney! if task.valid?
      task
    end

    def update(task_attrs)
      task = JudgeCaseAssignment.new(task_attrs)
      task.reassign_to_attorney! if task.valid?
      task
    end

    def repository
      @repository ||= QueueRepository
    end
  end
end
