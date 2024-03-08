# frozen_string_literal: true

describe  Events::CreateClaimantOnEvent do
  context "Event::CreateClaimantOnEvent.process!" do
    let(:event_double) { double("Event") }
    let(:veteran_double) { double("Veteran", file_number: "DCR02272024", participant_id:"VET03072024") }
    let(:claim_review) { double("ClaimReview", veteran_is_not_claimant: true )}
    let(:decision_review_double) { double("DecisionReview", legacy_opt_in_approved: false) }
    let(:claimant){ double("Claimant", participant_id: "03072024", payee_code: "00", type: "DependentClaimant", decision_review: decision_review_double )}
    let(:event_record_double) { double("EventRecord") }
    it "creates non-veteran claimant" do
      allow(Claimant).to receive(:create_without_intake!).and_return(claimant)
      allow(EventRecord).to receive(:create!).and_return(event_record_double)
      expect(Claimant).to receive(:create_without_intake!).with(participant_id: "03072024", payee_code: "00", type:"DependentClaimant")
    end
  end
end
