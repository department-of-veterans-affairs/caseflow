# frozen_string_literal: true

describe ClaimantValidator, :postgres do
  let(:veteran) { create(:veteran) }
  let(:claimant) do
    Claimant.new(
      decision_review: decision_review,
      participant_id: participant_id,
      payee_code: payee_code,
      type: type
    )
  end
  let(:address_line_1) { "123 Some Road" }
  let(:address_line_2) { "Suite A" }
  let(:address_line_3) { nil }
  let(:city) { "Springfield" }
  let(:decision_review) { HigherLevelReview.new(benefit_type: "compensation") }
  let(:participant_id) { "different from the veteran's" }
  let(:payee_code) { "10" }
  let(:type) { "DependentClaimant" }

  before do
    allow(claimant).to receive(:address_line_1).and_return(address_line_1)
    allow(claimant).to receive(:address_line_2).and_return(address_line_2)
    allow(claimant).to receive(:address_line_3).and_return(address_line_3)
    allow(claimant).to receive(:city).and_return(city)
    allow(decision_review).to receive(:veteran).and_return(veteran)
  end

  subject do
    ClaimantValidator.new(claimant).validate
    decision_review.errors
  end

  describe "#validate" do
    context "claimant is valid" do
      it "sets no errors" do
        expect(subject[:claimant]).to be_empty
      end

      context "claimant has a nil city" do
        let(:city) { nil }

        it "sets no errors" do
          expect(subject[:claimant]).to be_empty
        end
      end
    end

    context "claimant has no participant id" do
      let(:participant_id) { nil }
      it "sets a claimant required error" do
        expect(subject[:veteran_is_not_claimant]).to contain_exactly(ClaimantValidator::ERRORS[:claimant_required])
      end
    end

    context "claimant is missing a payee code" do
      let(:payee_code) { nil }
      it "sets a missing payee code error" do
        expect(subject[:benefit_type]).to contain_exactly(ClaimantValidator::ERRORS[:payee_code_required])
      end
    end

    context "claimant is missing address" do
      let(:address_line_1) { nil }
      it "sets an address required error" do
        expect(subject[:claimant]).to contain_exactly(ClaimantValidator::ERRORS[:claimant_address_required])
      end
    end

    context "claimant has an invalid address line" do
      let(:address_line_2) { "Apt  3" }
      it "sets an invalid address line error" do
        expect(subject[:claimant]).to contain_exactly(ClaimantValidator::ERRORS[:claimant_address_invalid])
      end
    end

    context "claimant has an invalid city" do
      let(:city) { "An improbably lengthy city name that exceeds 30 characters" }
      it "sets an invalid address city error" do
        expect(subject[:claimant]).to contain_exactly(ClaimantValidator::ERRORS[:claimant_city_invalid])
      end
    end
    context "decision_review_created_event claimant is missing address" do
      let(:decision_review2) do
        HigherLevelReview.new(benefit_type: "compensation", veteran_file_number: veteran.file_number)
      end
      let(:person) { Person.find_or_create_by_participant_id("12345678") }
      let(:person_event_record) do
        EventRecord.create!(event: event2, evented_record: person)
      end
      let(:claimant2) do
        Claimant.new(
          decision_review: decision_review2,
          participant_id: "12345678",
          payee_code: payee_code,
          type: type
        )
      end
      let(:address_line_1) { nil }
      let(:event2) { DecisionReviewCreatedEvent.create!(reference_id: "2") }
      let(:decision_review_event_record) do
        EventRecord.create!(event: event2, evented_record: decision_review2)
      end

      it "creates no error" do
        expect(subject[:claimant2]).to be_empty
      end
    end
  end
end
