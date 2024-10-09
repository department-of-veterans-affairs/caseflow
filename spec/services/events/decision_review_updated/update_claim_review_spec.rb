# frozen_string_literal: true

RSpec.describe Events::DecisionReviewUpdated::UpdateClaimReview do
  let!(:event) { DecisionReviewUpdatedEvent.create!(reference_id: "1") }
  let!(:epe) { create(:end_product_establishment, :active_hlr) }
  let!(:hlr) { epe.source }
  let!(:payload) { Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.example_response }

  describe ".process" do
    context "legacy_opt_in_approved true to false" do
      before do
        hlr.update!(legacy_opt_in_approved: true)
      end

      it "updates the value to false" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["legacy_opt_in_approved"] = false
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.legacy_opt_in_approved).to eq(false)
      end
    end
    context "legacy_opt_in_approved false to true" do
      before do
        hlr.update!(legacy_opt_in_approved: false)
      end

      it "updates the value to true" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["legacy_opt_in_approved"] = true
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.legacy_opt_in_approved).to eq(true)
      end
    end
  end
end
