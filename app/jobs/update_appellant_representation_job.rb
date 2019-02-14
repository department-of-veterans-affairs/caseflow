class UpdateAppellantRepresentationJob < CaseflowJob
  queue_as :low_priority

  # TODO: Add a timer to this job to see how long it runs. Maybe make it "asyncable"?
  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user
    Appeal.active.each(&:sync_tracking_tasks)
  end
end
