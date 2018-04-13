class JudgeCaseAssignment
  include ActiveModel::Model

  attr_accessor :task_id, :assigned_by, :assigned_to, :appeal_id, :appeal_type

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
    return Appeal.find(:appeal_id).vacols_id if appeal_id
    task_id.split("-", 2).first if task_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= QueueRepository
    end
  end
end
