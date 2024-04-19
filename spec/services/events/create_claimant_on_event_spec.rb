# frozen_string_literal: true

# rubocop:disable Layout/LineLength

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:decision_review) { create(:higher_level_review, veteran_file_number: create(:veteran).file_number) }
  let(:parser) do
    instance_double("ParserDouble",
                    person_first_name: "Sam",
                    person_last_name: "Jackson",
                    person_middle_name: "L",
                    person_ssn: "543627321",
                    person_date_of_birth: DateTime.now - 30.years,
                    person_email_address: "samjackson@pulpfiction.com",
                    claimant_name_suffix: "",
                    claim_review_veteran_is_not_claimant: true,
                    claimant_participant_id: "7479234",
                    claimant_type: "Claimant",
                    claimant_payee_code: "0002")
  end

  describe ".process" do
    context "when veteran is not the claimant" do
      it "creates a new claimant and returns its id" do
        expect(Person.find_by(participant_id: parser.claimant_participant_id)).to eq(nil)
        expect {
          described_class.process!(event: event, parser: parser, decision_review: decision_review)
        }.to change { EventRecord.count }.by(2).and change { Claimant.count }.by(1)

        expect(described_class.process!(event: event, parser: parser, decision_review: decision_review)).to eq(Claimant.last)
        expect(Person.find_by(participant_id: parser.claimant_participant_id)).to be_present
      end

      it "does not create a new claimant if veteran is the claimant" do
        allow(parser).to receive(:claim_review_veteran_is_not_claimant).and_return(false)

        expect(Claimant).not_to receive(:find_or_create_by!)

        expect(EventRecord).not_to receive(:create!)

        expect(described_class.process!(event: event, parser: parser, decision_review: decision_review)).to be_nil

        expect(Person.find_by(participant_id: parser.claimant_participant_id)).to eq(nil)
      end
    end
  end
end

# rubocop:enable Layout/LineLength
