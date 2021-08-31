# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  validates :parent, presence: true,
                     parentTask: { task_types: VhaCamo },
                     on: :create

  # before_validation :set_assignee

  # Actions that can be taken on both organization and user tasks
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
  ].freeze

  # Actions a user can take on a task assigned to someone on their team
  # USER_ACTIONS = [
  #   Constants.TASK_ACTIONS.COMPLETE_TASK.to_h,
  # ].concat(TASK_ACTIONS).freeze

  # Actions that make sense only for Org-assigned tasks
  # ORG_ACTIONS = [
  #   Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
  # ].concat(TASK_ACTIONS).freeze

  def self.label
    COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
  end

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    TASK_ACTIONS
    # if task_is_assigned_to_users_organization?(user)
    #   ORG_ACTIONS
    # elsif user_actions_available?(user)
    #   USER_ACTIONS
    # else
    #   []
    # end
  end
end
