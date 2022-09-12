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
end
