describe SyncIntakeJob do
  context ".perform" do
    it "calls recreate_issues_from_contentions and sync_ep_status" do
      ramp_election = instance_double(RampElection)
      expect(RampElection).to receive(:active).and_return([ramp_election]).twice
      allow(ramp_election).to receive(:recreate_issues_from_contentions!).and_return(true)
      allow(ramp_election).to receive(:sync_ep_status!).and_return(true)

      SyncIntakeJob.perform_now

      expect(ramp_election).to have_received(:recreate_issues_from_contentions!)
      expect(ramp_election).to have_received(:sync_ep_status!)
    end
  end
end
