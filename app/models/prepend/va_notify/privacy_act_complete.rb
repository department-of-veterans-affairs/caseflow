# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActComplete
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  def cascade_closure_from_child_task?(child_task)
    super
    if status == Constants.TASK_STATUSES.completed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
