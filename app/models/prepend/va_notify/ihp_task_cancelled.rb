# frozen_string_literal: true

# Public: Module used to update the IHP Task Pending column to FALSE
# This Module prepends the anonymous function 'update_appeal_state' within app/models/task.rb
# There is a callback within app/models/task.rb that will trigger 'update_appeal_state' to run
# whenver a task is updated.  This module will check if task is a type of IHP task, if the task
# is the parent task of all other IHP tasks on the appeal tree, and if the status has been updated
# to 'cancelled'.  When all of these conditions are met, the record correlated to the current task's
# appeal will update the column IHP TASK PENDING within the appeal states table to be FALSE.

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
