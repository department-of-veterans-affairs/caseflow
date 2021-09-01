# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
  ].freeze

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    TASK_ACTIONS
  end
end
