# frozen_string_literal: true

class ClearAndUnmistakeableErrorMailTask < MailTask
  def available_actions(user)
    if LitigationSupport.singleton.user_has_access?(user)
      return super.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)
    end

    super
  end

  def self.label
    COPY::CLEAR_AND_UNMISTAKABLE_ERROR_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
