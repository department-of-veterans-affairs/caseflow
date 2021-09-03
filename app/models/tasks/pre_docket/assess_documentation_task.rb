# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  validates :parent, presence: true,
                     parentTask: { task_type: VhaDocumentSearchTask },
                     on: :create

  # Actions that can be taken on both organization and user tasks
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.COMPLETE_TASK.to_h
  ].freeze

  def self.label
    COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
  end


  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    TASK_ACTIONS
  end
end
