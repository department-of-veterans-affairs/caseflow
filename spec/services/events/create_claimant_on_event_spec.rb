# frozen_string_literal: true

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:decision_review) { create(:higher_level_review, veteran_file_number: create(:veteran).file_number) }
  let(:parser) do
    instance_double("ParserDouble",
                    claim_review_veteran_is_not_claimant: true,
                    veteran_participant_id: "7479234",
                    claimant_payee_code: "0002")
  end

  describe ".process" do
    context "when veteran is not the claimant" do
      it "creates a new claimant and returns its id" do
        expect {
          described_class.process!(event: event, parser: parser, decision_review: decision_review)
        }.to change { EventRecord.count }.by(1).and change { Claimant.count }.by(1)

        expect(described_class.process!(event: event, parser: parser, decision_review: decision_review)).to eq(Claimant.last)
      end

      it "does not create a new claimant if veteran is the claimant" do
        allow(parser).to receive(:claim_review_veteran_is_not_claimant).and_return(false)

        expect(Claimant).not_to receive(:find_or_create_by!)

        expect(EventRecord).not_to receive(:create!)

        expect(described_class.process!(event: event, parser: parser, decision_review: decision_review)).to be_nil
      end
    end
  end
end
