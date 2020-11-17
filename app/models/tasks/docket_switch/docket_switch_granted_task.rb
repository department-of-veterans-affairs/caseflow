# frozen_string_literal: true

class DocketSwitchGrantedTask < AttorneyTask
  def available_actions(user)
    actions = super(user)

    if ClerkOfTheBoard.singleton.user_has_access?(user)
      if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
        actions.push(Constants.TASK_ACTIONS.DOCKET_SWITCH_GRANTED.to_h)
      end
    end

    actions
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
