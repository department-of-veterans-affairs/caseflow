# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    if assigned_to.is_a?(VhaProgramOffice)
      return [Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h]
    end

    if assigned_to.is_a?(VhaRegionalOffice)
      return []
    end

    []
  end
end
