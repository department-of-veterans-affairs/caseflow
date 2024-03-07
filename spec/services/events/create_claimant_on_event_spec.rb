RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { create(:event, reference_id: 123) }
  let!(:epe) { create(:end_product_establishment, reference_id: event.reference_id) }
  let!(:veteran) { epe.veteran }
  let!(:claimant_params) do
    {
      decision_review: epe.source,
      participant_id: veteran.participant_id,
      payee_code: epe.payee_code,
      decision_review_type: epe.source_type
    }
  end

  describe "#process" do
    context "when is_veteran_claimant is true" do
      it "returns the event reference id" do
        expect(described_class.process(event, true)).to eq(event.reference_id)
      end
    end

    context "when is_veteran_claimant is false" do
      it "creates a new claimant and returns its id" do
        expect { described_class.process(event, false) }.to change { Claimant.count }.by(1)
        claimant = Claimant.last
        expect(claimant.decision_review).to eq(claimant_params[:decision_review])
        expect(claimant.participant_id).to eq(claimant_params[:participant_id])
        expect(claimant.payee_code).to eq(claimant_params[:payee_code])
        expect(claimant.decision_review_type).to eq(claimant_params[:decision_review_type])
      end

      it "creates a new EventRecord associating the event with the claimant" do
        expect { described_class.process(event, false) }.to change { EventRecord.count }.by(1)
        event_record = EventRecord.last
        expect(event_record.backfill_record).to be_a(Claimant)
      end

      it "returns the id of the newly created claimant" do
        expect(described_class.process(event, false)).to eq(Claimant.last.id)
      end
    end
  end
end
