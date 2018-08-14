# This job syncs a RampElection with up to date BGS and VBMS data
class RampElectionSyncJob < CaseflowJob
  queue_as :low_priority

  def perform(ramp_election_id)
    self.class.application_attr :intake
    RequestStore.store[:current_user] = User.system_user

    RampElection.find(ramp_election_id).sync!
  end
end
