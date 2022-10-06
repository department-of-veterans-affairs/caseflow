# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Privacy Act request complete"
  # rubocop:enable all

  def update_status_if_children_tasks_are_closed(child_task)
    # original method defined in app/models/task.rb
    super_return_value = super
    if ((type.to_s.include?("Foia") && !parent&.type.to_s.include?("Foia")) ||
       (type.to_s.include?("PrivacyAct") && !parent&.type.to_s.include?("PrivacyAct"))) &&
       status == Constants.TASK_STATUSES.completed
      # appellant notification call
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/task.rb
  # for Privacy Act Tasks that are only assigned to an Organization
  def update_with_instructions(params)
    super_return_value = super
    if type.to_s == "PrivacyActTask" && assigned_to_type == "Organization" &&
       status == Constants.TASK_STATUSES.completed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
