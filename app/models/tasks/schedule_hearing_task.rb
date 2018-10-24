class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params, current_user)
      root_task = RootTask.find_by(appeal_id: params[:appeal].id)
      if !root_task
        root_task = RootTask.create!(appeal_id: params[:appeal].id,
                                     appeal_type: "LegacyAppeal",
                                     assigned_to_id: current_user.id)
      end
      params[:parent_id] = root_task.id

      super(params, current_user)
    end

    def create_child_task(parent, current_user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      parent.update!(status: :on_hold)

      create!(
        appeal: parent.appeal,
        appeal_type: "LegacyAppeal",
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: assignee,
        instructions: params[:instructions]
      )
    end
  end

  def available_actions(_user)
    [
      {
        label: "Assign hearing",
        value: "modal/mark_task_complete"
      }
    ]
  end
end
