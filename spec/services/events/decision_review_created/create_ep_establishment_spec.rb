# frozen_string_literal: true

# rubocop:disable Layout/LineLength

describe Events::DecisionReviewCreated::CreateEpEstablishment do
  context "Events::DecisionReviewCreated::CreateEpEstablishment.process!" do
    # set up variables station_id, end_product_establishment, claim_review, user, event
    let!(:user_double) { double("User", id: 1) }
    let!(:claim_review) { create(:higher_level_review) }
    # conversions to mimic parser logic
    let!(:converted_long) { Time.zone.at(171_046_496_764_2) }
    let!(:converted_claim_date) { logical_date_converter(202_403_14) }
    let!(:parser_double) do
      double("ParserDouble",
             station_id: "101",
             epe_payee_code: "00",
             epe_claim_date: converted_claim_date,
             epe_code: "030HLRRPMC",
             epe_committed_at: converted_long,
             epe_established_at: converted_long,
             epe_last_synced_at: converted_long,
             epe_limited_poa_access: nil,
             epe_limited_poa_code: nil,
             epe_modifier: "030",
             epe_reference_id: "337534",
             epe_synced_status: "RW",
             epe_benefit_type_code: "1",
             epe_development_item_reference_id: nil,
             claimant_participant_id: "1826209")
    end
    it "creates an a End Product Establishment and Event Record" do
      allow(EndProductEstablishment).to receive(:create!).and_return(parser_double)
      expect(EndProductEstablishment).to receive(:create!).with(
        payee_code: "00",
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: "1",
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
        user_id: 1,
        development_item_reference_id: nil,
        claimant_participant_id: "1826209"
      ).and_return(parser_double)
      described_class.process!(parser: parser_double, claim_review: claim_review, user: user_double)
    end

    # needed to convert the logical date int for the expect block
    def logical_date_converter(logical_date_int)
      # Extract year, month, and day components
      year = logical_date_int / 100_00
      month = (logical_date_int % 100_00) / 100
      day = logical_date_int % 100
      Date.new(year, month, day)
    end

    context "when an error occurs" do
      it "raises the error" do
        allow(EndProductEstablishment).to receive(:create!).and_raise(Caseflow::Error::DecisionReviewCreatedEpEstablishmentError)
        expect do
          described_class.process!(parser: parser_double,
                                   claim_review: claim_review, user: user_double)
        end.to raise_error(Caseflow::Error::DecisionReviewCreatedEpEstablishmentError)
      end
    end
  end
end

# rubocop:enable Layout/LineLength
