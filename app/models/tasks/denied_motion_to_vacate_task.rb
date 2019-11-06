# frozen_string_literal: true

class DeniedMotionToVacateTask < DecidedMotionToVacateTask
  def available_actions(user)
    actions = super(user)

    actions.push(Constants.TASK_ACTIONS.MARK_MOTION_TO_VACATE_TASK_COMPLETE.to_h)

    actions
  end

  def self.label
    COPY::DENIED_MOTION_TO_VACATE_TASK_LABEL
  end

  def self.org
    LitigationSupport.singleton
  end
end
