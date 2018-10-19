class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params_array, current_user)
      params_array.each do |params|
        root_task = RootTask.find_by(appeal_id: params[:appeal].id)
        if !root_task
          root_task = RootTask.create!(appeal_id: params[:appeal].id,
                                       appeal_type: "LegacyAppeal",
                                       assigned_to_id: current_user.id)
        end
        params[:parent_id] = root_task.id
      end

      super(params_array, current_user)
    end
  end

  def available_actions(_user)
    [
      {
        label: "Assign hearing",
        value: "modal/assign_hearing"
      },
      {
        label: "On hold",
        value: "modal/on_hold"
      }
    ]
  end
end
