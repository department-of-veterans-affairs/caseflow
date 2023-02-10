# frozen_string_literal: true

# Public: This Module is used to notify the appellant when an IHP type task is created and update
# the VSO IHP COMPLETE column of the correlated Appeal State record to be TRUE.
# This Module prepends relevant functions to do this.  The method 'create_ihp_tasks!' is defined
# within app/workflows/ihp_tasks_factory.rb and is called during intake.  When an appellant has an IHP
# writing POA and selects either Evidence Submission OR Direct Review, the appellant will be notified.
# The method 'create_from_params(params, user)' is defined within app/models/tasks/colocated_task.rb
# and is called within the queue app.  Whenever IHP is selected as an admin action, the appellant will be notified.
# The method 'update_appeal_state_when_ihp_created' is an abstract method that is defined in app/models/tasks.rb
# There is a callback within app/models/task.rb that will trigger 'update_appeal_state_on_task_creation' to run
# whenever a task is created (which in turn calls 'update_appeal_state_when_ihp_created').  The method
# 'update_appeal_state_when_ihp_created' will check if task being created is an IHP type task.  If the created task
# is an IHP type task, then the record correlated to the current task's appeal will have the column VSO IHP PENDING
# within the Appeal States table updated to be TRUE.

module IhpTaskPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP pending"
  # rubocop:enable all

  # All variants of IHP Tasks
  IHP_TYPE_TASKS = %w[IhpColocatedTask InformalHearingPresentationTask].freeze

  # original method defined in app/workflows/ihp_tasks_factory.rb

  # Purpose: Notify Appellant that an IHP task is pending
  #
  # Params: NONE
  #
  # Response: Send VSO IHP pending notification to appellant
  def create_ihp_tasks!
    super_return_value = super
    appeal_tasks_created = super_return_value.map { |task| task.class.to_s }
    if appeal_tasks_created.any?("InformalHearingPresentationTask")
      MetricsService.record("Sending VSO IHP pending notification to VA Notify "\
        "for #{@parent.appeal.class} ID #{@parent.appeal.id}",
                            service: nil,
                            name: "AppellantNotification.notify_appellant") do
        AppellantNotification.notify_appellant(@parent.appeal, @@template_name)
      end
    end
    super_return_value
  end

  # original method defined in app/models/tasks/colocated_task.rb

  # Purpose: Notify Appellant that an IHP task is pending
  #
  # Params: NONE
  #
  # Response: Send VSO IHP pending notification to appellant
  def create_from_params(params, user)
    super_return_value = super
    task_array = []
    super_return_value&.appeal.tasks.each { |task| task_array.push(task.class.to_s) }
    if super_return_value.class.to_s == "IhpColocatedTask" && task_array.include?("IhpColocatedTask")
      appeal = super_return_value.appeal
      MetricsService.record("Sending VSO IHP pending notification to VA Notify for #{appeal.class} "\
        "ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.notify_appellant") do
        AppellantNotification.notify_appellant(appeal, @@template_name)
      end
    end
    super_return_value
  end

  # original method in app/models/task.rb

  # Purpose: Update Record in Appeal States Table
  #
  # Params: NONE
  #
  # Response: Update 'vso_ihp_pending' column to True
  def update_appeal_state_when_ihp_created
    if IHP_TYPE_TASKS.include?(type)
      MetricsService.record("Updating VSO_IHP_PENDING column to TRUE & VSO_IHP_COMPLETE column to FALSE in"\
        " Appeal States Table for #{appeal.class} ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_pending")
      end
    end
  end
end
