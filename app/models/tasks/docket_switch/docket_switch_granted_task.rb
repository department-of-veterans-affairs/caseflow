# frozen_string_literal: true

class DocketSwitchGrantedTask < AttorneyTask
  def available_actions(user)
    actions = []

    if ClerkOfTheBoard.singleton.user_has_access?(user)
      actions += default_actions
      if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
        actions.push(Constants.TASK_ACTIONS.DOCKET_SWITCH_GRANTED.to_h)
      end
    end

    actions
  end

  # We don't want the default attorney task action, so specifying just those that we want
  def default_actions
    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
    ]
  end

  class << self
    def label
      COPY::DOCKET_SWITCH_GRANTED_TASK_LABEL
    end

    def verify_user_can_create!(user, parent)
      parent.is_a?(DocketSwitchRulingTask) ? true : super(user, parent)
    end
  end
end
