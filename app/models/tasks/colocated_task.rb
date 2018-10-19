class ColocatedTask < Task
  include RoundRobinAssigner

  validates :action, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  after_update :update_location_in_vacols

  class << self
    # Override so that each ColocatedTask for an appeal gets assigned to the same colocated staffer.
    def create_many_from_params(params_array, _)
      params_array.each do |params|
        if params.key?("instructions") && !params[:instructions].is_a?(Array)
          params["instructions"] = [params["instructions"]]
        end
      end
      create(params_array)
    end

    def create(tasks)
      ActiveRecord::Base.multi_transaction do
        assignee = next_assignee
        records = [tasks].flatten.each_with_object([]) do |task, result|
          result << super(task.merge(assigned_to: assignee))
          result
        end
        if records.map(&:valid?).uniq == [true] && records.first.legacy?
          AppealRepository.update_location!(records.first.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end
        records
      end
    end

    private

    def list_of_assignees
      Constants::CoLocatedTeams::USERS[Rails.current_env]
    end
  end

  def update_if_hold_expired!
    update!(status: Constants.TASK_STATUSES.in_progress) if on_hold_expired?
  end

  def on_hold_expired?
    return true if placed_on_hold_at && on_hold_duration && placed_on_hold_at + on_hold_duration.days < Time.zone.now
    false
  end

  private

  def update_location_in_vacols
    if saved_change_to_status? &&
       completed? &&
       appeal_type == LegacyAppeal.name &&
       all_tasks_completed_for_appeal?
      AppealRepository.update_location!(appeal, location_based_on_action)
    end
  end

  def location_based_on_action
    case action.to_sym
    when :translation, :schedule_hearing
      LegacyAppeal::LOCATION_CODES[action.to_sym]
    else
      assigned_by.vacols_uniq_id
    end
  end

  def all_tasks_completed_for_appeal?
    appeal.tasks.where(type: ColocatedTask.name).map(&:status).uniq == [Constants.TASK_STATUSES.completed]
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end
end
