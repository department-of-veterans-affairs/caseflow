# frozen_string_literal: true

class DocketSwitchDeniedTask < AttorneyTask
  def available_actions(user)
    actions = super(user)

    if ClerkOfTheBoard.singleton.user_has_access?(user)
      if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_change, user: user)
        actions.push(Constants.TASK_ACTIONS.DENY_DOCKET_SWITCH.to_h)
      end
    end

    actions
  end

  class << self
    def label
      COPY::DOCKET_DENIED_TASK_LABEL
    end
  end
end
