describe RampElectionSyncJob do
  context ".perform" do
    let!(:ramp_election) { create(:ramp_election, :established) }
    let!(:end_product_established) do
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: ramp_election.veteran_file_number,
        reference_id: Generators::EndProduct.build(veteran_file_number: ramp_election.veteran_file_number).claim_id
      )
    end

    it "syncs ramp election" do
      RampElectionSyncJob.perform_now(ramp_election.id)

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      resultant_end_product_establishment = EndProductEstablishment.find_by(source: ramp_election)
      expect(resultant_end_product_establishment.last_synced_at).to_not eq(nil)
    end
  end
end
