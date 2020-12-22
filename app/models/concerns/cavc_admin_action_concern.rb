# frozen_string_literal: true

# A concern for any tasks that will be created as admin actions before sending the cavc 90 letter to a veteran. Allows
# these admin actions to be created as children of distribution tasks
module CavcAdminActionConcern
  extend ActiveSupport::Concern

  CAVC_USER_TASK_TYPES = [
    SendCavcRemandProcessedLetterTask.name,
    CavcRemandProcessedLetterResponseWindowTask.name
  ].freeze

  class_methods do
    def verify_user_can_create!(user, parent_task)
      creating_from_cavc_workflow?(user, parent_task) || super(user, parent_task)
    end

    def creating_from_cavc_workflow?(user, parent_task)
      parent_task&.type == DistributionTask.name && (
        CavcLitigationSupport.singleton.user_is_admin?(user) ||
        parent_task.appeal.tasks.open.where(type: CAVC_USER_TASK_TYPES, assigned_to: user).exists?
      )
    end
  end

  # Use the existence of an organization-level task to prevent duplicates since there should only ever be one org-level
  # task active at a time for a single appeal.
  def verify_org_task_unique
    return super unless self.class.creating_from_cavc_workflow?(assigned_by, parent)

    if assigned_to.is_a?(Organization) && appeal.tasks.open.where(type: type, assigned_to: assigned_to).any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        docket_number: appeal.docket_number,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end
end
