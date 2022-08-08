# frozen_string_literal: true

# Module to notify appellant when an appeal gets docketed
module AppealDocketed
  extend AppellantNotification
  @@template_name = name.split("::")[1]

  def create_tasks_on_intake_success!
    super
    distribution_task = DistributionTask.find_by(appeal_id: id)
    if distribution_task
      AppellantNotification.notify_appellant(self, @@template_name)
    end
  end

  def docket_appeal
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
