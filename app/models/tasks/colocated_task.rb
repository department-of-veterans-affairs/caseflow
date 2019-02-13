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
        team_tasks = super(params_array.map { |p| p.merge(assigned_to: Colocated.singleton) }, user)

        all_tasks = team_tasks.map { |team_task| [team_task, team_task.children.first] }.flatten

        all_tasks.map(&:appeal).uniq.each do |appeal|
          if appeal.is_a? LegacyAppeal
            AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
          end
        end

        all_tasks
      end
    end

    def verify_user_can_create!(user, parent)
      if parent
        super(user, parent)
      elsif !(user.attorney_in_vacols? || user.judge_in_vacols?)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
      end
    end
  end

  def available_actions(user)
    if assigned_to != user
      if task_is_assigned_to_user_within_organization?(user) && Colocated.singleton.admins.include?(user)
        return [Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h]
      end

      return []
    end

    available_actions_with_conditions([
                                        Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
                                        Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.to_h
                                      ])
  end

  def available_actions_with_conditions(core_actions)
    if %w[translation schedule_hearing].include?(action) && appeal.is_a?(LegacyAppeal)
      send_to_team = Constants.TASK_ACTIONS.SEND_TO_TEAM.to_h
      send_to_team[:label] = format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, Constants::CO_LOCATED_ADMIN_ACTIONS[action])
      return core_actions.unshift(send_to_team)
    end

    core_actions.unshift(Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h)

    if action == "translation" && appeal.is_a?(Appeal)
      core_actions.push(Constants.TASK_ACTIONS.SEND_TO_TRANSLATION.to_h)
    end

    core_actions
  end

  def actions_available?(_user)
    active?
  end

  private

  def create_and_auto_assign_child_task(_options = {})
    super(appeal: appeal)
  end

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
    appeal.tasks.active.where(type: ColocatedTask.name).none?
  end

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
