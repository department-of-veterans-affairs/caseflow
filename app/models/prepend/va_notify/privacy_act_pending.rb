# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Pending
module PrivacyActPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def create_privacy_act_task
    # original method defined in app/models/tasks/foia_colocated_task.rb
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
