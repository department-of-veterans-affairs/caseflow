# frozen_string_literal: true

class ReviewMotionToVacateTask < ColocatedTask
  VACATE_MOTION_AVAILABLE_ACTIONS = [
    Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h,
    Constants.TASK_ACTIONS.SEND_MOTION_TO_VACATE_TO_JUDGE.to_h
  ].freeze

  def available_actions(user)
    if LitigationSupport.singleton.user_has_access?(user)
      return super + VACATE_MOTION_AVAILABLE_ACTIONS
    end

    super
  end

  def self.label
    COPY::REVIEW_MOTION_TO_VACATE_TASK_LABEL
  end

  def enable_draft_motion
    FeatureToggle.enabled?(:review_motion_to_vacate) && available_actions(user)
  end
end
