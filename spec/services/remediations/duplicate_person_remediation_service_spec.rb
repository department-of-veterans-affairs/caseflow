# frozen_string_literal: true

RSpec.describe Remediations::DuplicatePersonRemediationService, type: :service do
  let(:updated_person) { instance_double("Person", id: 1, participant_id: "updated_participant_id") }
  let(:duplicate_person1) { instance_double("Person", id: 2, participant_id: "duplicate_participant_id_1") }
  let(:duplicate_person2) { instance_double("Person", id: 3, participant_id: "duplicate_participant_id_2") }
  let(:duplicate_person_ids) { [duplicate_person1.id, duplicate_person2.id] }
  let!(:event1) { PersonUpdatedEvent.create!(reference_id: "1") }
  let!(:event_record) { EventRecord.create!(event_id: event1.id, evented_record_type: "Person", evented_record_id: 1) }

  let(:service) do
    described_class.new(
      updated_person_id: updated_person.id,
      duplicate_person_ids: duplicate_person_ids,
      event_record: event_record
    )
  end

  let(:column_mapping) do
    {
      Claimant => :participant_id,
      DecisionIssue => :participant_id,
      EndProductEstablishment => :claimant_participant_id,
      RequestIssue => :veteran_participant_id,
      Notification => :participant_id
    }
  end

  before do
    # Mock finding the updated person
    allow(Person).to receive(:find_by).with(id: updated_person.id).and_return(updated_person)

    allow(Person).to receive(:where).with(id: duplicate_person_ids).and_return([duplicate_person1, duplicate_person2])

    # Mocking each association class to return records_double for where and expect update_all
    column_mapping.each do |klass, column_name|
      records_double = double("ActiveRecord::Relation")

      # Use symbol keys instead of string keys in where
      allow(klass).to receive(:where).with(column_name => %w[duplicate_participant_id_1 duplicate_participant_id_2])
        .and_return(records_double)
      allow(records_double).to receive(:update_all).with(column_name => updated_person.participant_id)
    end

    # Mock destroy! on duplicate persons
    allow(duplicate_person1).to receive(:destroy!)
    allow(duplicate_person2).to receive(:destroy!)
  end

  describe "#remediate!" do
    context "when remediation is successful" do
      it "updates all records with duplicate participant_ids to the updated person participant_id" do
        expect(service.remediate!).to be_truthy

        column_mapping.each do |klass, column_name|
          expect(klass).to have_received(:where)
            .with(column_name => %w[duplicate_participant_id_1 duplicate_participant_id_2])
          expect(klass.where(column_name => %w[duplicate_participant_id_1 duplicate_participant_id_2]))
            .to have_received(:update!).with(column_name => updated_person.participant_id)
        end
      end

      it "destroys duplicate persons" do
        service.remediate!

        expect(duplicate_person1).to have_received(:destroy!)
        expect(duplicate_person2).to have_received(:destroy!)
      end
    end

    context "when an error occurs during remediation" do
      before do
        # Force `find_and_update_records` to return false to simulate a failure
        allow(service).to receive(:find_and_update_records).and_return(false)
      end

      it "logs the error and does not destroy duplicate persons" do
        result = service.remediate!

        expect(result).to be_falsey
        expect(duplicate_person1).not_to have_received(:destroy!)
        expect(duplicate_person2).not_to have_received(:destroy!)
      end
    end
  end
end
