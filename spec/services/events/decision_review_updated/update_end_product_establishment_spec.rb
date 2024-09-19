# frozen_string_literal: true

RSpec.describe Events::DecisionReviewUpdated::UpdateEndProductEstablishment do
  let!(:event) { DecisionReviewUpdatedEvent.create!(reference_id: "1") }
  let!(:epe) { create(:end_product_establishment, :active_hlr) }
  let!(:payload) { Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.example_response }

  describe ".process" do
    context "updating code, synced_status and last_synced_at" do
      before do
        epe.update!(
          code: nil,
          synced_status: nil,
          last_synced_at: nil
        )
      end

      it "updates the value to false" do
        hash = JSON.parse(payload)
        hash["detail_type"] = "HigherLevelReview"
        hash["end_product_establishment"]["reference_id"] = epe.reference_id.to_s
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, hash)
        expect do
          described_class.process!(event: event, parser: parser)
        end.to change { EventRecord.count }.by(1)

        epe.reload
        expect(epe.code).to eq(parser.end_product_establishment_code)
        expect(epe.synced_status).to eq(parser.end_product_establishment_synced_status)
        expect(epe.last_synced_at).to eq(parser.end_product_establishment_last_synced_at)
      end
    end
  end
end
