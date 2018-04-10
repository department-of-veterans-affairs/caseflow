describe SyncIntakeJob do
  context ".perform" do
    it "calls recreate_issues_from_contentions and sync_ep_status" do
      spy = 0
      allow_any_instance_of(RampElection).to receive(:recreate_issues_from_contentions!) do spy += 1 end
      allow_any_instance_of(RampElection).to receive(:sync_ep_status!) do spy += 1 end

      user = User.create!(station_id: "123", css_id: "456")

      ramp_election = RampElection.create!(
        veteran_file_number: "1",
        established_at: Time.zone.now
      )

      RampElectionIntake.create!(
        user_id: user.id,
        detail: ramp_election,
        completion_status: "success"
      )

      SyncIntakeJob.perform_now

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      expect(spy).to eq(2)
    end
  end
end
