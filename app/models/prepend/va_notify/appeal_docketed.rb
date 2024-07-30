# frozen_string_literal: true

# Public: This Module is used to notify the appellant when an Appeal is Docketed and update the correlated record within the Appeal State Table.
# An Appeal is considered docketed when a DistributionTask is created.
# We prepend 'create_tasks_on_intake_success!' to notify the appellant that their appeal is docketed.
# This method is called upon the successful intake of an appeal that does not require a PreDocketTask (like when there are VHA Request Issues).
# We also prepend 'docket_appeal' to notify the appellant that their appeal is docketed.
# This method is called when a PreDocketTask is completed, causing a DistributionTask to be created.
# The method 'update_appeal_state_when_appeal_docketed' is an abstract method that is defined in app/models/tasks.rb
# There is a callback within app/models/task.rb that will trigger 'update_appeal_state_on_task_creation' to run
# whenever a task is created (which in turn calls 'update_appeal_state_when_appeal_docketed').  The method
# 'update_appeal_state_when_appeal_docketed' will check if task being created is a DistributionTask.  If the created task
# is a DistributionTask, then the record correlated to the current task's appeal will have the column 'appeal_docketed'
# within the Appeal States table updated to be TRUE.

# Module to notify appellant when an appeal gets docketed
module AppealDocketed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal docketed"
  # rubocop:enable all

  # original method defined in app/models/appeal.rb

  # Purpose: Notify Appellant that their appeal has been docketed
  #
  # Params: NONE
  #
  # Response: Send Appeal Docketed notification to appellant
  def create_tasks_on_intake_success!
    super_return_value = super
    distribution_task = tasks.of_type(:DistributionTask).first
    if distribution_task
      MetricsService.record("Sending Appeal docketed notification to VA Notify "\
        "for #{self.class} ID #{self.id}",
                            service: nil,
                            name: "AppellantNotification.notify_appellant") do
        AppellantNotification.notify_appellant(self, @@template_name)
      end
    end
    super_return_value
  end

  # original method defined in app/models/pre_docket_task.rb

  # Purpose: Notify Appellant that their appeal has been docketed
  #
  # Params: NONE
  #
  # Response: Send Appeal Docketed notification to appellant
  def docket_appeal
    super_return_value = super
    MetricsService.record("Sending Appeal docketed notification to VA Notify "\
      "for #{appeal.class} ID #{appeal.id}",
                          service: nil,
                          name: "AppellantNotification.notify_appellant") do
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method in app/models/task.rb

  # Purpose: Update Record in Appeal States Table
  #
  # Params: NONE
  #
  # Response: Update 'appeal_docketed' column to True
  def update_appeal_state_when_appeal_docketed
    if type == "DistributionTask"
      MetricsService.record("Updating APPEAL_DOCKETED column in Appeal States Table to TRUE for #{appeal.class} "\
        "ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "appeal_docketed")
      end
    end
  end
end
