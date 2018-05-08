# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ApplicationJob
  queue_as :low_priority
  application_attr :intake

  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user
    RampElection.sync_all!
  end
end
