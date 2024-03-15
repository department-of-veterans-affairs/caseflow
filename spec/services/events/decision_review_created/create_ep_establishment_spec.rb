# frozen_string_literal: true

describe Events::DecisionReviewCreated::CreateEpEstablishment do
  context "Events::DecisionReviewCreated::CreateEpEstablishment.process!" do
    # set up variables station_id, end_product_establishment, claim_review, user, event
    let!(:station_id) { "101" }
    let!(:user_double) { double("User", id: 1) }
    let!(:event_double) { double("Event") }
    let!(:claim_review) { create(:higher_level_review) }
    # conversions for expect block
    let!(:converted_claim_date) { logical_date_converter(202_403_14) }
    let!(:converted_long) { Time.zone.at(171_046_496_764_2) }
    let!(:end_product_establishment_double) do
      double("EndProductEstablishmentDouble",
             payee_code: "00",
             claim_date: 202_403_14,
             code: "030HLRRPMC",
             committed_at: 171_046_496_764_2,
             established_at: 171_046_496_764_2,
             last_synced_at: 171_046_496_764_2,
             limited_poa_access: nil,
             limited_poa_code: nil,
             modifier: "030",
             reference_id: "337534",
             synced_status: "RW")
    end
    let(:event_record_double) { double("EventRecord") }
    it "creates an a End Product Establishment and Event Record" do
      allow(EndProductEstablishment).to receive(:create!).and_return(end_product_establishment_double)
      allow(EventRecord).to receive(:create!).and_return(event_record_double)
      expect(EndProductEstablishment).to receive(:create!).with(
        payee_code: "00",
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: "compensation",
        claim_date: converted_claim_date,
        code: "030HLRRPMC",
        committed_at: converted_long,
        established_at: converted_long,
        last_synced_at: converted_long,
        limited_poa_access: nil,
        limited_poa_code: nil,
        modifier: "030",
        reference_id: "337534",
        station: "101",
        synced_status: "RW",
        user_id: 1
      ).and_return(end_product_establishment_double)
      expect(EventRecord).to receive(:create!)
        .with(event: event_double, backfill_record: end_product_establishment_double).and_return(event_record_double)
      described_class.process!(station_id, end_product_establishment_double, claim_review, user_double, event_double)
    end

    # needed to convert the logical date int for the expect block
    def logical_date_converter(logical_date_int)
      # Extract year, month, and day components
      year = logical_date_int / 100_00
      month = (logical_date_int % 100_00) / 100
      day = logical_date_int % 100
      date = Date.new(year, month, day)
      date
    end

    context "when an error occurs" do
      let(:error) do
        Caseflow::Error::DecisionReviewCreatedEpEstablishmentError.new("Unable to create End Product Establishement")
      end
      it "raises the error" do
        allow(EndProductEstablishment).to receive(:create!).and_raise(error)
        expect do
          described_class.process!(station_id, end_product_establishment_double,
                                   claim_review, user_double, event_double)
        end.to raise_error(error)
      end
    end
  end
end
