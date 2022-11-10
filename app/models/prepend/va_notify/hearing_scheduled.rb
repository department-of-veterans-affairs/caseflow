# frozen_string_literal: true

# Module to notify appellant if Hearing is Scheduled
module HearingScheduled
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Hearing scheduled"
  # rubocop:enable all

  rescue_from AppealTypeNotImplementedError do |exception|
    Rails.logger.error(exception)
    Rails.logger.error("Invalid Appeal Type for HearingScheduled")
  end

  def create_hearing(task_values)
    # original method defined in app/models/tasks/schedule_hearing_task.rb
    super_return_value = super
    AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "hearing_scheduled")
    AppellantNotification.notify_appellant(appeal, @@template_name)
    super_return_value
  end
end
