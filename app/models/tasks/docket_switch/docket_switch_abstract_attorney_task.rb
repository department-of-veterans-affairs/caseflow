# frozen_string_literal: true

class DocketSwitchAbstractAttorneyTask < AttorneyTask
  def available_actions(user)
    return [] unless ClerkOfTheBoard.singleton.user_has_access?(user)

    actions = self.class.default_actions
    if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
      actions.push(self.class.task_action.to_h)
    end

    actions
  end

  # Allow docket switch attorney tasks to also be assigned to CotB
  def assigned_to_role_is_valid
    super unless assigned_to.is_a?(ClerkOfTheBoard)
  end

  class << self
    # Necessary to have here to avoid bugs, but must implement in subclass
    def label
      "Docket Switch Abstract Attorney Task"
    end

    # Implement in subclass
    def task_action; end

    def verify_user_can_create!(user, parent)
      parent.is_a?(DocketSwitchRulingTask) ? true : super(user, parent)
    end

    # We don't want the default attorney task action, so specifying just those that we want
    def default_actions
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
      ]
    end
  end

  private

  def only_open_task_of_type
    # This overrides the validation inherited from the parent class, AttorneyTask,
    # to allow the docket switch flow to remain functional
  end
end
