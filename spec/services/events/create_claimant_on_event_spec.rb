# frozen_string_literal: true

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:decision_review) { create(:higher_level_review, veteran_file_number: create(:veteran).file_number) }
  let(:vbms_claimant) do
    instance_double("VbmsClaimant",
      claim_review: double("ClaimReview"),
      claimant: double("Claimant",
        participant_id: "12345",
        payee_code: "01",
        type: "individual"
      )
    )
  end

  describe ".process" do
    context "when veteran is not the claimant" do
      it "creates a new claimant and returns its id" do
        allow(vbms_claimant.claim_review).to receive(:veteran_is_not_claimant).and_return(true)

        expect {
          described_class.process!(event: event, vbms_claimant: vbms_claimant, decision_review: decision_review)
        }.to change { EventRecord.count }.by(1).and change { Claimant.count }.by(1)

        expect(described_class.process!(event: event, vbms_claimant: vbms_claimant, decision_review: decision_review)).to eq(Claimant.last)
      end

      it "does not create a new claimant if veteran is the claimant" do
        allow(vbms_claimant.claim_review).to receive(:veteran_is_not_claimant).and_return(false)

        expect(Claimant).not_to receive(:find_or_create_by!)

        expect(EventRecord).not_to receive(:create!)

        expect(described_class.process!(event: event, vbms_claimant: vbms_claimant, decision_review: decision_review)).to be_nil
      end
    end
  end
end
