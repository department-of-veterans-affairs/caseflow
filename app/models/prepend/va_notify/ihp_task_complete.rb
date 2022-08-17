# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
module IhpTaskComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  # def update_status_if_children_tasks_are_closed(child_task)
  #   # original method defined in app/models/task.rb
  #   super
  #   if %w[InformalHearingPresentationTask IhpColocatedTask].include?(type) 
  #     AppellantNotification.notify_appellant(appeal, @@template_name)
  #   end
  # end

  def update_from_params(params, user)
    super
    if %w[InformalHearingPresentationTask IhpColocatedTask].include?(type) &&
       params[:status] == Constants.TASK_STATUSES.completed &&
       params[:assigned_to_type] == "Organization"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
