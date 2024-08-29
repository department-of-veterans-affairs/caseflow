# frozen_string_literal: true

# Abstract base class for "tasks not related to an appeal" added to a correspondence during Correspondence Intake.
class CorrespondenceMailTask < CorrespondenceTask
  class << self
    # allows inbound ops team users to create tasks in intake
    def verify_user_can_create!(user, parent)
      return true if InboundOpsTeam.singleton.user_has_access?(user)

      super(user, parent)
    end
  end

  self.abstract_class = true

  def self.create_child_task(parent, current_user, params)
    Task.create!(
      type: name,
      appeal: parent.appeal,
      appeal_type: Correspondence.name,
      assigned_by_id: child_assigned_by_id(parent, current_user),
      parent_id: parent.id,
      assigned_to: params[:assigned_to] || child_task_assignee(parent, params),
      instructions: params[:instructions]
    )
  end

  def reassign_users
    users_list = []
    # return users if the assignee is an organization
    if assigned_to.is_a?(Organization)
      users_list << assigned_to&.users.pluck(:css_id)
    end
    # return the users from other orgs
    if assigned_to.is_a?(User)
      users_list = []
      assigned_to.organizations.each { |org| users_list << org.users.reject { |user| user == assigned_to}.pluck(:css_id) }
      users_list.flatten
    end

    users_list
  end

  # rubocop: disable Metrics/AbcSize
  def self.available_actions(user)
    return [] unless user

    options = [
      Constants.TASK_ACTIONS.CHANGE_CORR_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.MARK_TASK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.RETURN_TO_INBOUND_OPS.to_h,
      Constants.TASK_ACTIONS.CANCEL_CORR_TASK.to_h,
      Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h
    ]


    if user.is_a? (User)
      options.insert(2, Constants.TASK_ACTIONS.REASSIGN_CORR_TASK_TO_PERSON.to_h)
    else
      options.insert(2, Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h)
    end

    options
  end
  # rubocop: enable Metrics/AbcSize
end
