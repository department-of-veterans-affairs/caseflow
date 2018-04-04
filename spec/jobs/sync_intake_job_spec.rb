describe SyncIntakeJob do
  context ".perform" do
    it "calls recreate_issues_from_contentions and sync_ep_status" do
      ramp_election = RampElection.create!(
        veteran_file_number: "1",
      )

      intake = RampElectionIntake.create!(
        user_id: 1, 
        detail_id: ramp_election.id,
        completion_status: "success"
      )

      SyncIntakeJob.perform_now
    end
  end
end
