# frozen_string_literal: true

# Module to notify appellant if Hearing is Scheduled
module HearingScheduled
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  def create_hearing(task_values)
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
