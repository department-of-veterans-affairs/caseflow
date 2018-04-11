describe SyncIntakeJob do
  context ".perform" do
    it "calls recreate_issues_from_contentions and sync_ep_status" do
      expect(RampElection).to receive(:sync_all!)

      SyncIntakeJob.perform_now

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
    end
  end
end
