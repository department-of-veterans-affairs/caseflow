# frozen_string_literal: true

class VacateMotionMailTask < MailTask
  def available_actions(user)
    actions = super(user)

    if LitigationSupport.singleton.user_has_access?(user)
      actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)

      if assigned_to.is_a?(User) && FeatureToggle.enabled?(:review_motion_to_vacate, user: user)
        actions.push(Constants.TASK_ACTIONS.SEND_MOTION_TO_VACATE_TO_JUDGE.to_h)
      end
    end

    actions
  end

  def self.label
    COPY::VACATE_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
