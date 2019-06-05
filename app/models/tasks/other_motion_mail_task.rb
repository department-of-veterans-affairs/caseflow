# frozen_string_literal: true

class OtherMotionMailTask < MailTask
  def self.label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end
