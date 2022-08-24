# frozen_string_literal: true

# Module to notify appellant if IHP Task is pending
module IhpTaskPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP pending"
  # rubocop:enable all

  # AMA Appeals
  def create_ihp_tasks!
    # original method defined in app/workflows/ihp_tasks_factory.rb
    rtn = super
    AppellantNotification.notify_appellant(@parent.appeal, @@template_name)
    rtn
  end

  # Legacy Appeals Mixin used in app/models/tasks/colocated_task.rb
  def notify_appellant_if_ihp(appeal)
    if name == "IhpColocatedTask"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
