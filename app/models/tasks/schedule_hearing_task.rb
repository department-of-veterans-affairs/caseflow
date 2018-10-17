class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params_array, current_user)
      params_array.each do |params|
        root_task = RootTask.find_by(appeal_id: params[:appeal_id])
        if !root_task
          root_task = RootTask.create!(appeal_id: params[:appeal_id],
                                       appeal_type: "LegacyAppeal",
                                       assigned_to_id: current_user.id)
        end
        params[:parent_id] = root_task.id
      end

      super(params_array, current_user)
    end
  end
end
