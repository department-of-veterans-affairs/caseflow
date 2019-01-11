class ColocatedTask < Task
  validates :action, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid
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
  end

  def set_assigned_at_and_update_parent_status
    self.assigned_at = created_at unless assigned_at
    parent&.update(status: :on_hold)
  end

  def available_actions(_user)
    actions = [
      {
        label: COPY::COLOCATED_ACTION_PLACE_HOLD,
        value: Constants::CO_LOCATED_ACTIONS["PLACE_HOLD"]
      },
      Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.to_h
    ]

    if %w[translation schedule_hearing].include?(action) && appeal.class.name.eql?("LegacyAppeal")
      actions.unshift(
        label: format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, Constants::CO_LOCATED_ADMIN_ACTIONS[action]),
        value: "modal/send_colocated_task"
      )
    else
      actions.unshift(
        label: COPY::COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
        value: "modal/mark_task_complete"
      )
    end

    actions
  end

  def actions_available?(user)
    return false if completed? || assigned_to != user

    true
  end

  def assign_to_privacy_team_data
    org = PrivacyTeam.singleton

    {
      selected: org,
      options: [{ label: org.name, value: org.id }],
      type: GenericTask.name
    }
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
    appeal.tasks.where(type: ColocatedTask.name).map(&:status).uniq == [Constants.TASK_STATUSES.completed]
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
