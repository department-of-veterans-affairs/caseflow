# frozen_string_literal: true

RSpec.describe Events::DecisionReviewRemanded::CreateRemandClaimReview do
  let!(:event) { DecisionReviewRemandedEvent.create!(reference_id: "1") }
  let(:parser) do
    instance_double("ParserDouble",
                    claim_review_auto_remand: true,
                    claim_review_benefit_type: "compensation",
                    detail_type: "SupplementalClaim",
                    claim_review_filed_by_va_gov: true,
                    claim_review_legacy_opt_in_approved: false,
                    claim_review_receipt_date: DateTime.now.to_s,
                    claim_review_veteran_is_not_claimant: false,
                    claim_review_establishment_attempted_at: DateTime.now.to_s,
                    claim_review_establishment_last_submitted_at: DateTime.now.to_s,
                    claim_review_establishment_processed_at: DateTime.now.to_s,
                    claim_review_establishment_submitted_at: DateTime.now.to_s,
                    veteran_file_number: "7479234"
                    )
  end

  describe ".process" do
    context "when a Remand SupplementalClaim payload is received" do
      it "creates a new supplemental claim" do
        allow(parser).to receive(:detail_type).and_return("SupplementalClaim")

        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1).and change { SupplementalClaim.count }.by(1)

        expect(described_class.process!(event: event, parser: parser)).to eq(SupplementalClaim.last)

        claim_review = SupplementalClaim.last
        expect(claim_review.auto_remand).to eq(parser.claim_review_auto_remand)
        expect(claim_review.benefit_type).to eq(parser.claim_review_benefit_type)
        expect(claim_review.filed_by_va_gov).to eq(parser.claim_review_filed_by_va_gov)
        expect(claim_review.legacy_opt_in_approved).to eq(parser.claim_review_legacy_opt_in_approved)
        expect(claim_review.veteran_is_not_claimant).to eq(parser.claim_review_veteran_is_not_claimant)
        expect(claim_review.establishment_attempted_at).to eq(parser.claim_review_establishment_attempted_at)
        expect(claim_review.establishment_last_submitted_at).to eq(parser.claim_review_establishment_last_submitted_at)
        expect(claim_review.establishment_processed_at).to eq(parser.claim_review_establishment_processed_at)
        expect(claim_review.establishment_submitted_at).to eq(parser.claim_review_establishment_submitted_at)
        expect(claim_review.veteran_file_number).to eq(parser.veteran_file_number)
      end
    end

    context "when an error occurs" do
      it "raises DecisionReviewRemandedCreateRemandClaimReviewError" do
        allow(SupplementalClaim).to receive(:create!)
          .and_raise(Caseflow::Error::DecisionReviewRemandedCreateRemandClaimReviewError, "Error message")

        expect do
          described_class.process!(parser: parser, event: event)
        end.to raise_error(Caseflow::Error::DecisionReviewRemandedCreateRemandClaimReviewError, "Error message")
      end
    end
  end
end
