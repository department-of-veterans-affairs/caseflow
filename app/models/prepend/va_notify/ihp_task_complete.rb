# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
# Public: This Module is used to notify the appellant when an IHP type task is completed and update
# the VSO IHP COMPLETE column of the correlated Appeal State record to be TRUE.
# This Module prepends relevant functions to do this.  The method 'update_from_params(params, user)' is defined
# within app/models/task.rb.  When an IHP Task is completed, the appellant will be notified.
# There is a callback within app/models/task.rb that will trigger 'update_appeal_state_on_status_change' to run
# whenever a task is completed (which in turn calls 'update_appeal_state_when_ihp_completed').  The method
# 'update_appeal_state_when_ihp_completed' will check if task being completed is an IHP type task.  If the task
# is an IHP type task, then the record correlated to the current task's appeal will have the column VSO IHP COMPLETE
# within the Appeal States table updated to be TRUE.
module IhpTaskComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP complete"
  # rubocop:enable all

  # All variants of IHP Tasks
  IHP_TYPE_TASKS = %w[IhpColocatedTask InformalHearingPresentationTask].freeze

  # original method in app/models/task.rb

  # Purpose: Notify Appellant that an IHP task has been completed
  #
  # Params: NONE
  #
  # Response: Send VSO IHP complete notification to appellant
  def update_from_params(params, user)
    super_return_value = super
    if %w[InformalHearingPresentationTask IhpColocatedTask].include?(type) &&
       params[:status] == Constants.TASK_STATUSES.completed
      MetricsService.record("Sending VSO IHP complete notification to VA Notify for #{appeal.class} "\
        "ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.notify_appellant") do
        AppellantNotification.notify_appellant(appeal, @@template_name)
      end
    end
    super_return_value
  end

  # original method in app/models/task.rb

  # Purpose: Update Record in Appeal States Table
  #
  # Params: NONE
  #
  # Response: Updated 'vso_ihp_complete' column to TRUE
  def update_appeal_state_when_ihp_completed
    if IHP_TYPE_TASKS.include?(type) &&
       !IHP_TYPE_TASKS.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.completed
      MetricsService.record("Updating VSO_IHP_COMPLETED column to TRUE & VSO_IHP_PENDING column to FALSE in Appeal"\
        " States Table for #{appeal.class} ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_complete")
      end
    end
  end
end
