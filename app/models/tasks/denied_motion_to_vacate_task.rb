# frozen_string_literal: true

class DeniedMotionToVacateTask < DecidedMotionToVacateTask
  def self.label
    COPY::DENIED_MOTION_TO_VACATE_TASK_LABEL
  end

  def org
    LitigationSupport.singleton
  end
end
