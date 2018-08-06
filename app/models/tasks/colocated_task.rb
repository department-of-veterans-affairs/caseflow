class ColocatedTask < Task
  validates :action, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

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
      (list_of_assignees.index(last_assignee_css_id) + 1) % list_of_assignees.length
    end

    def list_of_assignees
      Constants::CoLocatedTeams::USERS[Rails.current_env]
    end
  end

  private

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end
end
