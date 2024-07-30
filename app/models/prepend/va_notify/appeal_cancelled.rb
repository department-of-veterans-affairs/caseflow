# frozen_string_literal: true

# Public: Module to notify Appellant when Appeal is Cancelled
# This Module prepends the anonymous function 'update_appeal_state' within app/models/task.rb
# There is a callback within app/models/task.rb that will trigger 'update_appeal_state' to run
# when a root task is cancelled. The record correlated to the current root task's
# appeal will update the column appeal_cancelled within the appeal states table to TRUE.

module AppealCancelled
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal Cancelled"
  # rubocop:enable all

  # Original Method in app/models/task.rb
  # Purpose: Update Record in Appeal States Table
  #
  # Params: NONE
  #
  # Response: Updated 'appeal_cancelled' column to TRUE

  def update_appeal_state_when_appeal_cancelled
    if ["RootTask"].include?(type) && status == Constants.TASK_STATUSES.cancelled
      MetricsService.record("Updating APPEAL_CANCELLED column in Appeal States Table to TRUE "\
        "for #{appeal.class} ID #{appeal.id}",
                            service: :queue,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "appeal_cancelled")
      end
    end
  end

end
