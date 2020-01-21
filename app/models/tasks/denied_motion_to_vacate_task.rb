# frozen_string_literal: true

class DeniedMotionToVacateTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::DENIED_MOTION_TO_VACATE_TASK_LABEL
    end

    def org(_user)
      LitigationSupport.singleton
    end
  end

  def completion_contact
    COPY::CANCEL_TASK_CONTACT_LIT_SUPPORT
  end
end
