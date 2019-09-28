# frozen_string_literal: true

class DeniedMotionToVacateTask < GenericTask
  def available_actions(user)
    actions = super(user)

    actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)

    actions
  end

  def self.label
    COPY::DENIED_MOTION_TO_VACATE_TASK_LABEL
  end
end
