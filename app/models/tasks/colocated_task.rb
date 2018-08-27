class ColocatedTask < Task
  validates :action, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  after_update :update_location_in_vacols

  class << self
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

    def next_assignee
      User.find_or_create_by(css_id: next_assignee_css_id, station_id: User::BOARD_STATION_ID)
    end

    def latest_task
      order("created_at").last
    end

    def last_assignee_css_id
      latest_task ? latest_task.assigned_to.css_id : nil
    end

    def next_assignee_css_id
      list_of_assignees[next_assignee_index]
    end

    def next_assignee_index
      return 0 unless last_assignee_css_id
      return 0 unless list_of_assignees.index(last_assignee_css_id)
      (list_of_assignees.index(last_assignee_css_id) + 1) % list_of_assignees.length
    end

    def list_of_assignees
      Constants::CoLocatedTeams::USERS[Rails.current_env]
    end
  end

  private

  def update_location_in_vacols
    if saved_change_to_status? &&
       completed? &&
       appeal_type == "LegacyAppeal" &&
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
    appeal.tasks.where(type: "ColocatedTask").map(&:status).uniq == ["completed"]
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end
end
