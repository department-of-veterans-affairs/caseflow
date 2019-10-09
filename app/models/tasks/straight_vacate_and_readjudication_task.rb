# frozen_string_literal: true

class StraightVacateAndReadjudicationTask < GenericTask
  def available_actions(user)
    actions = super(user)

    actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)

    actions
  end

  def self.label
    COPY::STRAIGHT_VACATE_AND_READJUDICATION_TASK_LABEL
  end
end
