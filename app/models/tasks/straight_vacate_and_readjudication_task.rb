# frozen_string_literal: true

class StraightVacateAndReadjudicationTask < Task
  def available_actions(user)
    actions = super(user)

    actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)

    actions
  end

  def self.label
    COPY::STRAIGHT_VACATE_AND_READJUDICATION_TASK_LABEL
  end

  def update_status_if_children_tasks_are_closed(_child_task)
    if assigned_to.is_a?(Organization)
      return update!(status: :completed)
    end

    super
  end
end
