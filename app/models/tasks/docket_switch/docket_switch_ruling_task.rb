# frozen_string_literal: true

class DocketSwitchRulingTask < JudgeTask
  after_save :process!

  def process!
    close_parent_task if active?
  end

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

  private

  def close_parent_task
    parent.update(status: Constants.TASK_STATUSES.completed)
  end
end
