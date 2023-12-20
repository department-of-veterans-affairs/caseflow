# frozen_string_literal: true

class ReconsiderationMotionMailTask < MailTask
  def available_actions(user)
    if LitigationSupport.singleton.user_has_access?(user)
      return super.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)
    end

    super
  end

  def self.label
    COPY::RECONSIDERATION_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
