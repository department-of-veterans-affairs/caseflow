class HearingAdminActionTask < GenericTask
  validates :action, inclusion: { in: Constants::HEARING_ADMIN_ACTIONS.keys.map(&:to_s) }
  validates :assigned_by, presence: true
  validates :parent, presence: true
  validate :on_hold_duration_is_set, on: :update

  # rubocop:disable Metrics/AbcSize
  def available_actions(user)
    if assigned_to == user
      [
        Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    else
      [
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
      ]
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
