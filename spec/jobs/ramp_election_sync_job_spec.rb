describe RampElectionSyncJob do
  context ".perform" do
    let!(:ramp_election) { create(:ramp_election, :established) }

    it "syncs ramp election", focus: true do
      RampElectionSyncJob.perform_now(ramp_election.id)

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      expect(ramp_election.reload.end_product_status_last_synced_at).to_not eq(nil)
    end
  end
end
