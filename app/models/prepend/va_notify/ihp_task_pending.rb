# frozen_string_literal: true

# Module to notify appellant if IHP Task is pending
module IhpTaskPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP pending"
  # rubocop:enable all

  # original method defined in app/workflows/ihp_tasks_factory.rb
  def create_ihp_tasks!
    super_return_value = super
    appeal_tasks_created = super_return_value.map { |task| task.class.to_s }
    if appeal_tasks_created.any?("InformalHearingPresentationTask")
      AppellantNotification.notify_appellant(@parent.appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/tasks/colocated_task.rb
  def create_from_params(params, user)
    super_return_value = super
    task_array = []
    super_return_value&.appeal.tasks.each { |task| task_array.push(task.class.to_s) }
    if super_return_value.class.to_s == "IhpColocatedTask" && task_array.include?("IhpColocatedTask")
      AppellantNotification.notify_appellant(super_return_value.appeal, @@template_name)
    end
    super_return_value
  end
end
