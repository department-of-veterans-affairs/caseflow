# frozen_string_literal: true

# Module to notify appellant if Hearing is Scheduled
module HearingScheduled
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def create_hearing(task_values)
    # original method defined in app/models/tasks/schedule_hearing_task.rb
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
