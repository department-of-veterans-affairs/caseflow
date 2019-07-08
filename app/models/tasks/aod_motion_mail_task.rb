# frozen_string_literal: true

class AodMotionMailTask < MailTask
  def self.label
    COPY::AOD_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    AodTeam.singleton
  end
end
