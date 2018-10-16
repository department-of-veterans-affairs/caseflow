class MailTask < GenericTask
  def self.create_from_params(params_array, current_user)
    params_array.map do |params|
      root_task = RootTask.find_by(appeal_id: params[:appeal].id)
      # TODO: Die unless we find a RootTask.

      # TODO: Do we need to verify current user's access to the root task? Just confirm they are a mail user?
      # root_task.verify_user_access!(current_user)

      mail_task = create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )

      params[:parent_id] = mail_task.id
    end

    GenericTask.create_from_params(params_array, current_user)
  end
end
