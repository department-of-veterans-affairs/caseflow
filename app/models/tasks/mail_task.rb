class MailTask < GenericTask
  class << self
    def create_from_params(params, user)
      root_task = RootTask.find_by(appeal_id: params[:appeal].id)
      unless root_task
        fail(Caseflow::Error::NoRootTask, message: "Could not find root task for appeal with ID #{params[:appeal]}")
      end

      verify_user_can_create!(user, Task.find(params[:parent_id]))

      mail_task = create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )

      # Create a child task off of the mail organization's task so we can track how that task was created.
      params[:parent_id] = mail_task.id
      GenericTask.create_from_params(params, user)
    end
  end
end
