# frozen_string_literal: true

# A concern for any tasks that will be created as admin actions before sending the cavc 90 letter to a veteran. Allows
# these admin actions to be created as children of distribution tasks
module CavcAdminActionConcern
  extend ActiveSupport::Concern

  class_methods do
    def verify_user_can_create!(user, parent_task)
      creating_from_cavc_workflow?(user, parent_task) || super(user, parent_task)
    end

    def creating_from_cavc_workflow?(user, parent_task)
      return true if parent_task&.type == DistributionTask.name && (
                     CavcLitigationSupport.singleton.user_is_admin?(user) ||
                     SendCavcRemandProcessedLetterTask.open.where(assigned_to: user, appeal: parent_task.appeal).exists?
                   )

      false
    end
  end
end
