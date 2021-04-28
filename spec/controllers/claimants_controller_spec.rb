# frozen_string_literal: true

RSpec.describe ClaimantsController, :all_dbs, type: :controller do
  describe "PUT claimants/:participant_id/power_of_attorney" do
    let!(:cob_user) do
      ClerkOfTheBoard.singleton.add_user(create(:user))
      ClerkOfTheBoard.singleton.users.first
    end
    let(:original_poa) { create(:bgs_power_of_attorney) }
    let(:original_poa_last_synced_at) { original_poa.poa_last_synced_at }
    let(:participant_id) { original_poa.claimant_participant_id }
    let(:request_params) { { participant_id: participant_id } }

    before { User.authenticate!(user: cob_user) }

    subject { put(:refresh_claimant_poa, params: request_params) }

    it "updates poa information from BGS" do
      bgs_poa = instance_double(BgsPowerOfAttorney)
      expect(BgsPowerOfAttorney).to receive(:find_or_create_by_claimant_participant_id)
        .with(participant_id)
        .and_return(bgs_poa)
      expect(bgs_poa).to receive(:update_cached_attributes!)
      subject
    end

    it "returns an updated poa_last_synced_at value" do
      expect(subject.status).to eq 200
      expect(JSON.parse(subject.body)["poa"]["last_synced_at"]).to be > original_poa_last_synced_at
    end
  end
end
