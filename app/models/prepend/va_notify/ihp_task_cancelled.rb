# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
module IhpTaskCancelled
  extend AppellantNotification

  # All variants of IHP Tasks
  IHP_TYPE_TASKS = %w[IhpColocatedTask InformalHearingPresentationTask].freeze

  # original method in app/models/task.rb

  # Purpose: Update Record in Appeal States Table
  #
  # Params: NONE
  #
  # Response: Updated 'vso_ihp_pending' column to FALSE
  def update_appeal_state
    if IHP_TYPE_TASKS.include?(type) &&
       !IHP_TYPE_TASKS.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.cancelled
      MetricsService.record("Updating VSO_IHP_PENDING column in Appeal States Table to FALSE for #{appeal.class.to_s} ID #{appeal.id}",
                            service: :queue,
                            name: "AppellantNotification.appeal_mapper") do
        Rails.logger.debug ActiveSupport::LogSubscriber
          .new.send(:color, "Appeals_Mapper Method to update Appeal State Goes Here!", :green)
      end
    end
  end
end
