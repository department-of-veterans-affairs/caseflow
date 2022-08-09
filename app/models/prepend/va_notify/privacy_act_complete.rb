# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def cascade_closure_from_child_task?(child_task)
    # original method defined in app/models/tasks/foia_colocated_task.rb
    super
    if status == Constants.TASK_STATUSES.completed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
