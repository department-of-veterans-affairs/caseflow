# frozen_string_literal: true

# Module to notify appellant if Hearing is Scheduled
module HearingScheduled
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Hearing scheduled"
  # rubocop:enable all

  def create_hearing(task_values)
    # original method defined in app/models/tasks/schedule_hearing_task.rb
    super_return_value = super
    AppellantNotification.notify_appellant(appeal, @@template_name)
    super_return_value
  end

  # Purpose: Callback method when a hearing is created to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_scheduled
    MetricsService.record("Updating HEARING_SCHEDULED in Appeal States Table for #{appeal.class} ID #{appeal.id}",
                          name: "AppellantNotification.appeal_mapper") do
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "hearing_scheduled")
    end
  end
end
