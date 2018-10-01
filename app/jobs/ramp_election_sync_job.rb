# This job syncs a RampElection with up to date BGS and VBMS data
class RampElectionSyncJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(ramp_election_id)
    # TODO: DELETE ME
    # we only didn't remove this to prevent a bunch of queued up job failures
  end
end
