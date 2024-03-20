# frozen_string_literal: true

RSpec.describe Events::DecisionReviewCreated::CreateClaimReview do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:parser) do
    instance_double("ParserDouble",
                    benefit_type: "benefit type",
                    detail_type: "HigherLevelReview",
                    filed_by_va_gov: "maybe",
                    legacy_opt_in_approved: "legacy opt",
                    receipt_date: DateTime.now.to_s,
                    veteran_is_not_claimant: "veteran claim status",
                    establishment_attempted_at: "establishment attempted at",
                    establishment_last_submitted_at: "establishment last submitted at",
                    establishment_processed_at: "processed at time",
                    establishment_submitted_at: "submitted at",
                    veteran_file_number: "7479234")
  end

  describe ".process" do
    context "when intake is not HigherLevelReview" do
      it "creates a new supplemental claim" do
        allow(parser).to receive(:detail_type).and_return("NotHighLevelReview")

        expect {
          described_class.process!(event: event, parser: parser)
        }.to change { EventRecord.count }.by(1).and change { SupplementalClaim.count }.by(1)

        expect(described_class.process!(event: event, parser: parser)).to eq(SupplementalClaim.last)
      end
    end

    context "when intake is a HigherLevelReview" do
      it "creates a new supplemental claim" do
        expect {
          described_class.process!(event: event, parser: parser)
        }.to change { EventRecord.count }.by(1).and change { HigherLevelReview.count }.by(1)

        expect(described_class.process!(event: event, parser: parser)).to eq(HigherLevelReview.last)
      end
    end

    context "when an error occurs" do
      it "raises DecisionReviewCreatedCreateClaimReviewError" do
        allow(HigherLevelReview).to receive(:create)
          .and_raise(Caseflow::Error::DecisionReviewCreatedCreateClaimReviewError, "Error message")

        expect {
          described_class.process!(event: event, parser: parser)
        }.to raise_error(Caseflow::Error::DecisionReviewCreatedCreateClaimReviewError, "Error message")
      end
    end
  end
end
