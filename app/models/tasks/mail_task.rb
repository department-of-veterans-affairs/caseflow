class MailTask < GenericTask
  class << self
    def create_from_params(params_array, current_user)
      verify_user_can_assign!(current_user)

      params_array.map do |params|
        root_task = RootTask.find_by(appeal_id: params[:appeal].id)
        unless root_task
          fail(Caseflow::Error::NoRootTask, message: "Could not find root task for appeal with ID #{params[:appeal]}")
        end

        mail_task = create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )

        params[:parent_id] = mail_task.id
      end

      GenericTask.create_from_params(params_array, current_user)
    end

    def verify_user_can_assign!(user)
      unless MailTeam.user_has_access?(user)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot create a mail task"
      end
    end
  end
end
