# frozen_string_literal: true

# Module to notify appellant when an appeal gets docketed
module AppealDocketed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal docketed"
  # rubocop:enable all

  def create_tasks_on_intake_success!
    # original method defined in app/models/appeal.rb
    super_return_value = super
    distribution_task = tasks.of_type(:DistributionTask).first
    if distribution_task
      AppellantNotification.notify_appellant(self, @@template_name)
    end
    super_return_value
  end

  def docket_appeal
    # original method defined in app/models/pre_docket_task.rb
    super_return_value = super
    AppellantNotification.notify_appellant(appeal, @@template_name)
    super_return_value
  end
end
