describe SyncIntakeJob do
  context ".perform" do
    it "calls recreate_issues_from_contentions and sync_ep_status" do
      slack_service = double("SlackService")
      expect(slack_service).to receive(:send_notification)

      allow_any_instance_of(SyncIntakeJob).to receive(:slack_service).and_return(slack_service)
      expect(RampClosedAppeal).to receive(:reclose_all!).and_return([])

      SyncIntakeJob.perform_now

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
    end
  end
end
