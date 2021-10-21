# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  DEFAULT_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
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
end
