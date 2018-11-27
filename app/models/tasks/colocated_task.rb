class ColocatedTask < GenericTask
  include RoundRobinAssigner

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
        assignee = next_assignee
        records = params_array.map do |params|
          team_task = create_from_params(params.merge(assigned_to: Colocated.singleton), user)
          individual_task = create_from_params(params.merge(assigned_to: assignee, parent: team_task), user)

          [team_task, individual_task]
        end.flatten

        individual_task = records.select { |r| r.assigned_to.is_a?(User) }.first
        if records.map(&:valid?).uniq == [true] && individual_task.legacy?
          AppealRepository.update_location!(individual_task.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end

        records
      end
    end

    private

    def list_of_assignees
      Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id)
    end
  end

  def available_actions(_user)
    actions = [
      {
        label: COPY::COLOCATED_ACTION_PLACE_HOLD,
        value: Constants::CO_LOCATED_ACTIONS["PLACE_HOLD"]
      }
    ]

    if %w[translation schedule_hearing].include?(action) && appeal.is_a?(LegacyAppeal)
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

  def no_actions_available?(user)
    # TODO: Move this to Colocated.singleton.user_has_access?(user).
    completed? || user.colocated_in_vacols?
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

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
