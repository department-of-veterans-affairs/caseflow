describe SyncIntakeJob do
  context ".perform" do
    let!(:ramp_election) { create(:ramp_election, :established) }

    it "calls recreate_issues_from_contentions and sync_ep_status" do
      slack_service = double("SlackService")
      expect(slack_service).to receive(:send_notification)

      allow_any_instance_of(SyncIntakeJob).to receive(:slack_service).and_return(slack_service)
      expect(RampElectionSyncJob).to receive(:perform_later).with(ramp_election.id)

      SyncIntakeJob.perform_now

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
    end
  end
end
