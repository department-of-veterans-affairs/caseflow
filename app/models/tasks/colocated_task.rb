class ColocatedTask < Task
  validates :action, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?
  validate :on_hold_duration_is_set, on: :update

  after_update :update_location_in_vacols

  class << self
    # Override so that each ColocatedTask for an appeal gets assigned to the same colocated staffer.
    def create_many_from_params(params_array, user)
      # Create all ColocatedTasks in one transaction so that if any fail they all fail.
      ActiveRecord::Base.multi_transaction do
        assignee = Colocated.singleton.next_assignee(self)
        records = params_array.map do |params|
          team_task = create_from_params(
            params.merge(assigned_to: Colocated.singleton), user
          )
          individual_task = create_from_params(params.merge(assigned_to: assignee, parent_id: team_task.id), user)

          [team_task, individual_task]
        end.flatten

        individual_task = records.select { |r| r.assigned_to.is_a?(User) }.first
        if records.map(&:valid?).uniq == [true] && individual_task.legacy?
          AppealRepository.update_location!(individual_task.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end

        records
      end
    end

    def verify_user_can_create!(user, parent)
      if parent
        super(user, parent)
      elsif !(user.attorney_in_vacols? || user.judge_in_vacols?)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
      end
    end

    private

    def list_of_assignees
      Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id)
    end
  end

  def automatically_assign_org_task?
    false
  end

  def available_actions(_user)
    actions = [Constants.TASK_ACTIONS.PLACE_HOLD.to_h, Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.to_h]

    if %w[translation schedule_hearing].include?(action) && appeal.class.name.eql?("LegacyAppeal")
      send_to_team = Constants.TASK_ACTIONS.SEND_TO_TEAM.to_h
      send_to_team[:label] = format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, Constants::CO_LOCATED_ADMIN_ACTIONS[action])
      actions.unshift(send_to_team)
    else
      actions.unshift(Constants.TASK_ACTIONS.SEND_BACK_TO_ATTORNEY.to_h)
    end

    actions
  end

  def actions_available?(user)
    return false if completed? || assigned_to != user

    true
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

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
