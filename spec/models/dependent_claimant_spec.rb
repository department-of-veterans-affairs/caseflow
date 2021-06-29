# frozen_string_literal: true

describe DependentClaimant, :postgres do
  let(:participant_id) { "pid" }
  let(:file_number) { "vfn" }
  let(:claimant) do
    create(:claimant,
           type: "DependentClaimant",
           participant_id: participant_id,
           decision_review: build(:appeal, veteran_file_number: file_number))
  end

  describe "#power_of_attorney" do
    let(:bgs_service) { BGSService.new }

    subject { claimant.power_of_attorney }
    context "when participant ID doesn't return any POA" do
      before do
        allow(BgsPowerOfAttorney).to receive(:bgs).and_return(bgs_service)
        allow(bgs_service).to receive(:fetch_poas_by_participant_ids).and_return({})
      end

      it "returns nil without using file number" do
        expect(subject).to be_nil
        expect(bgs_service).not_to receive(:fetch_poa_by_file_number)
      end
    end
  end
end
