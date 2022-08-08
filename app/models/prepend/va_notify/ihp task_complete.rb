# frozen_string_literal: true

  #Module to notify appellant if IHP Task is Complete
  module IhpTaskComplete 
    extend AppellantNotification
    @@template_name = self.name.split("::")[1]

    def update_status_if_children_tasks_are_closed(child_task)
      super
      if %w[RootTask DistributionTask AttorneyTask].include?(child_task.parent.type) &&
        (child_task.type.include?("InformalHearingPresentationTask") ||
        child_task.type.include?("IhpColocatedTask"))
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
      end
    end
  end