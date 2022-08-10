# frozen_string_literal: true

# Module to notify appellant if IHP Task is pending
module IhpTaskPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def create_ihp_tasks!
    # original method defined in app/workflows/ihp_tasks_factory.rb
    super
    AppellantNotification.notify_appellant(@parent.appeal, @@template_name)
  end

  def create_from_params(params, user)
    # original method defined in app/models/tasks/colocated_task.rb
    super
    if name == "IhpColocatedTask"
      AppellantNotification.notify_appellant(@parent.appeal, @@template_name)
    end
  end
end
