# frozen_string_literal: true

class DismissedMotionToVacateTask < DecidedMotionToVacateTask
  def self.label
    COPY::DISMISSED_MOTION_TO_VACATE_TASK_LABEL
  end

  def self.org(_user)
    LitigationSupport.singleton
  end

  def completion_contact
    COPY::CANCEL_TASK_CONTACT_LIT_SUPPORT
  end
end
