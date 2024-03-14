# frozen_string_literal: true

describe Events::DecisionReviewCreated::CreateEpEstablishment do
  context "Events::DecisionReviewCreated::CreateEpEstablishment.process!" do
    # set up variables station_id, end_product_establishment, claim_review, user, event
    let!(:station_id) { "101" }
    let!(:user_double) { double("User", id: 1) }
    let!(:event_double) { double("Event") }
    let!(:claim_review) { create(:higher_level_review) }
    let(:end_product_establishment_double) do
      instance_double("EndProductEstablishmentDouble",
                      payee_code: "00",
                      claim_date: 2.days.ago,
                      code: "030HLRRPMC",
                      committed_at: 170_206_714_500_0,
                      established_at: 170_206_714_500_0,
                      last_synced_at: 170_206_714_500_0,
                      limited_poa_access: nil,
                      limited_poa_code: nil,
                      modifier: "030",
                      reference_id: "337534",
                      synced_status: "RW")
    end
    let(:event_record_double) { double("EventRecord") }
    it "calls.process!" do
      allow(EndProductEstablishment).to receive(:create!).and_return(end_product_establishment_double)
      allow(EventRecord).to receive(:create!).and_return(event_record_double)
      described_class.process!(station_id, end_product_establishment_double, claim_review, user_double, event_double)
    end
  end
end
