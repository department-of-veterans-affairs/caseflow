# frozen_string_literal: true

class DismissedMotionToVacateTask < DecidedMotionToVacateTask
  def self.label
    COPY::DISMISSED_MOTION_TO_VACATE_TASK_LABEL
  end

  def self.org
    LitigationSupport.singleton
  end

  def completion_contact
    "the Litigation Support team"
  end
end
