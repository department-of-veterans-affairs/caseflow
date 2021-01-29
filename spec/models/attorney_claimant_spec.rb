# frozen_string_literal: true

describe AttorneyClaimant, :postgres do
  let(:claimant) { AttorneyClaimant.new(participant_id: participant_id) }
  let(:participant_id) { "25793481" }

  context "when no POA data exists for attorney's participant id" do
    before do
      allow(BgsPowerOfAttorney).to(
        receive(:find_or_create_by_claimant_participant_id).and_return(nil)
      )
    end

    it "returns nil POA instead of using veteran file number" do
      expect(claimant.power_of_attorney).to be_nil
    end
  end

  describe "#name" do
    let(:name) { "Generic Attorney, Esq." }
    let!(:bgs_attorney) do
      BgsAttorney.create!(participant_id: participant_id, name: name, record_type: "POA Attorney")
    end

    subject { claimant.name }

    it "uses data from BGS's list of attorneys" do
      expect(subject).to eq(name)
    end
  end
end
