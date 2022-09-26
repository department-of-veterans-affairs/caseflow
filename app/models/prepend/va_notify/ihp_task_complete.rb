# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
module IhpTaskComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP complete"
  # rubocop:enable all

  # original method in app/models/task.rb
  def update_from_params(params, user)
    super_return_value = super
    if %w[InformalHearingPresentationTask IhpColocatedTask].include?(type) &&
       params[:status] == Constants.TASK_STATUSES.completed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
