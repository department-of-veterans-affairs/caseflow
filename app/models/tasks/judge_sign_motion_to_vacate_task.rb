# frozen_string_literal: true

class JudgeSignMotionToVacateTask < JudgeTask
  def additional_available_actions(user)
    actions = [Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h]

    if assigned_to.is_a?(User) && FeatureToggle.enabled?(:review_motion_to_vacate, user: user)
      actions.push(Constants.TASK_ACTIONS.JUDGE_CHECKOUT_PULAC_CERULLO_REMINDER.to_h)
    end

    actions
  end

  def self.label
    COPY::JUDGE_SIGN_MOTION_TO_VACATE_TASK_LABEL
  end
end
