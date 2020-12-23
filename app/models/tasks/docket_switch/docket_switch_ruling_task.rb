# frozen_string_literal: true

class DocketSwitchRulingTask < JudgeTask

  def additional_available_actions(user)
    actions = []

    if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
      actions.push(Constants.TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.to_h)
    end

    actions
  end

  def self.label
    COPY::DOCKET_SWITCH_RULING_TASK_LABEL
  end
end
