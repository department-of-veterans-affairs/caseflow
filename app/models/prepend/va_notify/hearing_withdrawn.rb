# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
module HearingWithdrawn
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def cancel!
    # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
