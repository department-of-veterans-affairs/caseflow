# frozen_string_literal: true

class DocketSwitchRulingTask < JudgeTask
  def additional_available_actions(user)
    actions = []

    if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
      actions.push(Constants.TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.to_h)
    end

    actions
  end

  def timeline_title
    COPY::DOCKET_SWITCH_RULING_TASK_TITLE
  end

  class << self
    def label
      COPY::DOCKET_SWITCH_RULING_TASK_LABEL
    end

    def verify_user_can_create!(user, parent)
      parent.is_a?(RootTask) || parent.is_a?(DistributionTask) ? true : super(user, parent)
    end
  end
end
