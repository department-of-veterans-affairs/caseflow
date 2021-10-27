# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  validates :parent, presence: true,
                     on: :create

  def self.label
    COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
  end

  # Actions that can be taken on both organization and user tasks
  DEFAULT_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.READY_FOR_REVIEW.to_h
  ].freeze

  PO_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h
  ].freeze

  RO_ACTIONS = [].freeze

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    task_actions = []

    task_actions.concat(DEFAULT_ACTIONS)

    if assigned_to.is_a?(VhaProgramOffice)
      task_actions.concat(PO_ACTIONS)
    end

    if assigned_to.is_a?(VhaRegionalOffice)
      task_actions.concat(RO_ACTIONS)
    end

    task_actions
  end

  def when_child_task_completed(child_task)
    append_instruction(child_task.instructions.last) if child_task.assigned_to.is_a?(VhaRegionalOffice)

    super
  end
end
