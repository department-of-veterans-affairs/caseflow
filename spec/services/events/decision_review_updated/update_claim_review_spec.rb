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

    context "informal_conference true to false" do
      before do
        hlr.update!(informal_conference: true)
      end

      it "updates the value to false" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["informal_conference"] = false
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.informal_conference).to eq(false)
      end
    end
    context "informal_conference false to true" do
      before do
        hlr.update!(informal_conference: false)
      end

      it "updates the value to true" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["informal_conference"] = true
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.informal_conference).to eq(true)
      end
    end

    context "same_office true to false" do
      before do
        hlr.update!(same_office: true)
      end

      it "updates the value to false" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["same_office"] = false
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.same_office).to eq(false)
      end
    end
    context "same_office false to true" do
      before do
        hlr.update!(same_office: false)
      end

      it "updates the value to true" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        hash["claim_review"]["same_office"] = true
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        hlr.reload
        expect(hlr.same_office).to eq(true)
      end
    end
  end
end
