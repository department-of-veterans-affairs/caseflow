# frozen_string_literal: true

# rubocop:disable Layout/LineLength

RSpec.describe Events::CreateClaimantOnEvent do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:decision_review) { create(:higher_level_review, veteran_file_number: create(:veteran).file_number) }
  let!(:person) { create(:person, participant_id: "111111111") }
  let(:veteran_is_not_claimant_and_person_does_not_exist_parser) do
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
                    claimant_type: "DependentClaimant",
                    claimant_payee_code: "10")
  end
  let(:veteran_is_not_claimant_but_person_exists_parser) do
    instance_double("ParserDouble",
                    person_first_name: "Steve",
                    person_last_name: "Buscemi",
                    person_middle_name: "?",
                    person_ssn: "222222222",
                    person_date_of_birth: DateTime.now - 32.years,
                    person_email_address: "stevebuscemi@pulpfiction.com",
                    claimant_name_suffix: "",
                    claim_review_veteran_is_not_claimant: true,
                    claimant_participant_id: "111111111",
                    claimant_type: "DependentClaimant",
                    claimant_payee_code: "10")
  end
  let(:veteran_is_claimant_parser) do
    instance_double("ParserDouble",
                    person_first_name: "John",
                    person_last_name: "Travolta",
                    person_middle_name: "",
                    person_ssn: "987654321",
                    person_date_of_birth: DateTime.now - 31.years,
                    person_email_address: "johntravolta@pulpfiction.com",
                    claimant_name_suffix: "",
                    claim_review_veteran_is_not_claimant: false,
                    claimant_participant_id: "123456789",
                    claimant_type: "VeteranClaimant",
                    claimant_payee_code: "00")
  end

  let(:failing_veteran_is_claimant_parser) do
    instance_double("ParserDouble",
                    person_first_name: nil,
                    person_last_name: nil,
                    person_middle_name: "",
                    person_ssn: nil,
                    person_date_of_birth: DateTime.now - 31.years,
                    person_email_address: nil,
                    claimant_name_suffix: "",
                    claim_review_veteran_is_not_claimant: false,
                    claimant_participant_id: nil,
                    claimant_type: "VeteranClaimant",
                    claimant_payee_code: "00")
  end

  let(:veteran_is_not_claimant_and_person_does_not_existing_information) do
    instance_double("ParserDouble",
                    person_first_name: nil,
                    person_last_name: nil,
                    person_middle_name: nil,
                    person_ssn: nil,
                    person_date_of_birth: "",
                    person_email_address: nil,
                    claimant_name_suffix: "",
                    claim_review_veteran_is_not_claimant: true,
                    claimant_participant_id: "5382910292",
                    claimant_type: "DependentClaimant",
                    claimant_payee_code: "10")
  end

  describe ".process!" do
    context "when the veteran is not the claimant and the person DOES NOT exist in Caseflow" do
      it "a new person record is created" do
        expect(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to eq(nil)
        described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_exist_parser, decision_review: decision_review)
        expect(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to be_present
      end

      it "a new person record is created with nil values" do
        described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_existing_information, decision_review: decision_review)
        no_name_person = Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_existing_information.claimant_participant_id)

        expect(no_name_person.read_attribute(:first_name)).to be_nil
        expect(no_name_person.read_attribute(:last_name)).to be_nil
        expect(no_name_person.read_attribute(:middle_name)).to be_nil
        expect(no_name_person.read_attribute(:ssn)).to be_nil
        expect(no_name_person.read_attribute(:date_of_birth)).to be_nil
        expect(no_name_person.read_attribute(:email_address)).to be_nil
      end

      it "a single new dependent claimant record is created" do
        expect(Claimant.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to eq(nil)
        expect do
          described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_exist_parser, decision_review: decision_review)
        end.to change { Claimant.count }.by(1)
      end

      it "a new dependent claimant record is returned" do
        expect(Claimant.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to eq(nil)
        expect(described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_exist_parser, decision_review: decision_review)).to eq(Claimant.last)
      end

      # rubocop:disable Style/BlockDelimiters
      it "a new record of the new person that was created is added to the event_record table" do
        expect(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to eq(nil)
        expect {
          described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_exist_parser, decision_review: decision_review)
        }.to change { EventRecord.count }.by(1)
        expect(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id)).to be_present
        expect(EventRecord.last.evented_record_id).to eq(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id).id)
        expect(EventRecord.last.evented_record_type).to eq(Person.find_by(participant_id: veteran_is_not_claimant_and_person_does_not_exist_parser.claimant_participant_id).class.to_s)
      end
      # rubocop:enable Style/BlockDelimiters
    end

    context "when the veteran is not the claimant and the person DOES exist in Caseflow" do
      it "the person record is found" do
        expect(Person.find_by(participant_id: veteran_is_not_claimant_but_person_exists_parser.claimant_participant_id)).to be_present
        described_class.process!(event: event, parser: veteran_is_not_claimant_and_person_does_not_exist_parser, decision_review: decision_review)
        expect(Person.find_by(participant_id: veteran_is_not_claimant_but_person_exists_parser.claimant_participant_id)).to be_present
      end

      it "a single new dependent claimant record is created" do
        expect(Claimant.find_by(participant_id: veteran_is_not_claimant_but_person_exists_parser.claimant_participant_id)).to eq(nil)
        expect do
          described_class.process!(event: event, parser: veteran_is_not_claimant_but_person_exists_parser, decision_review: decision_review)
        end.to change { Claimant.count }.by(1)
      end

      it "a new dependent claimant record is returned" do
        expect(Claimant.find_by(participant_id: veteran_is_not_claimant_but_person_exists_parser.claimant_participant_id)).to eq(nil)
        expect(described_class.process!(event: event, parser: veteran_is_not_claimant_but_person_exists_parser, decision_review: decision_review)).to eq(Claimant.last)
      end

      it "no new records are added to the event_record table" do
        described_class.process!(event: event, parser: veteran_is_not_claimant_but_person_exists_parser, decision_review: decision_review)
        expect(EventRecord.last).to be_nil
      end
    end

    context "when the veteran is the claimant" do
      it "a single new veteran claimant record is created" do
        expect(Claimant.find_by(participant_id: veteran_is_claimant_parser.claimant_participant_id)).to eq(nil)
        expect do
          described_class.process!(event: event, parser: veteran_is_claimant_parser, decision_review: decision_review)
        end.to change { Claimant.count }.by(1)
      end

      it "a new veteran claimant record is returned" do
        expect(Claimant.find_by(participant_id: veteran_is_claimant_parser.claimant_participant_id)).to eq(nil)
        expect(described_class.process!(event: event, parser: veteran_is_claimant_parser, decision_review: decision_review)).to eq(Claimant.last)
      end

      it "no new records are added to the event_record table" do
        described_class.process!(event: event, parser: veteran_is_claimant_parser, decision_review: decision_review)
        expect(EventRecord.last).to be_nil
      end
    end

    context "when an error occurs" do
      it "the error is caught and the Caseflow::Error::DecisionReviewCreatedClaimantError is raised" do
        expect { described_class.process!(event: event, parser: failing_veteran_is_claimant_parser, decision_review: decision_review) }
          .to raise_error(Caseflow::Error::DecisionReviewCreatedClaimantError)
      end
    end
  end
end

# rubocop:enable Layout/LineLength
