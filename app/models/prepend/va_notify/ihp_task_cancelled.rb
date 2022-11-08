# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
module IhpTaskCancelled
  extend AppellantNotification

  # original method in app/models/task.rb
  def ihp_task?
    super_return_value = super
    if super_return_value &&
       !%w[IhpColocatedTask InformalHearingPresentationTask].freeze.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.cancelled
      Rails.logger.debug ActiveSupport::LogSubscriber.new.send(
        :color, "Appeals_Mapper Method to update Appeal State Goes Here!", :green
      )
    end
    super_return_value
  end
end
