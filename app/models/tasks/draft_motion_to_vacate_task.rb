# frozen_string_literal: true

class DraftMotionToVacateTask < JudgeTask
  def available_actions(user)
    [
      Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h
    ]
  end

  def self.label
    COPY::DRAFT_MOTION_TO_VACATE_TASK_LABEL
  end
end
