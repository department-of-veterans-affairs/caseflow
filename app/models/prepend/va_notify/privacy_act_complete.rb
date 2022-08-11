# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def update_status_if_children_tasks_are_closed(child_task)
    # original method defined in app/models/task.rb
    super
    if type.to_s.include?("Foia") || type.to_s.include?("PrivacyAct")
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
