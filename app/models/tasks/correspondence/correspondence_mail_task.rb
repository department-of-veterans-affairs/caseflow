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
      users_list << assigned_to&.users&.pluck(:css_id)&.reject do |current_user|
        current_user.include?(RequestStore.store[:current_user].css_id)
      end
    end
    # return the users from other orgs
    if assigned_to.is_a?(User)
      users_list = []
      assigned_to.organizations.each do |org|
        users_list << org.users.reject { |user| user == assigned_to }.pluck(:css_id)
      end
    end

    users_list.uniq.flatten!
  end

  # disable Metrics/AbcSize
  def available_actions(user)
    return [] unless user_can_work_task_correspondence_mail_task(user)

    options = [
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.COR_RETURN_TO_INBOUND_OPS.to_h
    ]

    if assigned_to.is_a? Organization
      options.insert(2, Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h)
    else
      options.insert(2, Constants.TASK_ACTIONS.REASSIGN_CORR_TASK_TO_PERSON.to_h)
    end

    options
  end

  def reassign_organizations
    if assigned_to.is_a?(Organization)
      Organization.where.not(id: assigned_to.id).assignable(self)
    else
      # Return all assignable organizations if the task is assigned to a user
      Organization.assignable(self)
    end
  end

  private

  def user_can_work_task_correspondence_mail_task(user)
    task_is_assigned_to_users_organization?(user) || assigned_to == user
  end
end
