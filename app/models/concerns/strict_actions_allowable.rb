# frozen_string_literal: true

##
# Concern to only allow actions on a task under strict conditions:
#   1) If the task is assigned to an organization, only an admin user in that organization may see actions
#   2) If the task is assigned to a user, only that user may see actions
#
# If either of these conditions is met, conditions set in superclasses' actions_allowable? methods will also apply

module StrictActionsAllowable
  extend ActiveSupport::Concern

  def actions_allowable?(user)
    # if this task is assigned to an Organization, no actions unless the user is an admin in that organization
    return false if assigned_to_type == Organization.name && !assigned_to.user_is_admin?(user)

    # if the task is assigned to a User, no actions unless the task is assigned to the user
    return false if assigned_to_type == User.name && assigned_to != user

    # go with default actions if none of the above conditions were met
    super
  end
end
