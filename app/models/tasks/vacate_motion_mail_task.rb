# frozen_string_literal: true

class VacateMotionMailTask < MailTask
  VACATE_MOTION_AVAILABLE_ACTIONS = [
    Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h,
    Constants.TASK_ACTIONS.LIT_SUPPORT_ASSIGN_JUDGE_DRAFT_MOTION_TO_VACATE.to_h
  ].freeze

  def available_actions(user)
    if LitigationSupport.singleton.user_has_access?(user)
      return super + VACATE_MOTION_AVAILABLE_ACTIONS
    end

    super
  end

  def self.label
    COPY::VACATE_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
