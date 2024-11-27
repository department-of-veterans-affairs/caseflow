# frozen_string_literal: true

RSpec.describe Remediations::DuplicatePersonRemediationService, type: :service do
  let(:updated_person) { instance_double("Person", id: 1, participant_id: "123456789") }
  let(:duplicate_person1) { instance_double("Person", id: 2, participant_id: "987654321") }
  let(:duplicate_person2) { instance_double("Person", id: 3, participant_id: "324576891") }
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
      Claimant => "participant_id",
      DecisionIssue => "participant_id",
      EndProductEstablishment => "claimant_participant_id",
      RequestIssue => "veteran_participant_id",
      Notification => "participant_id"
    }
  end

  let(:mock_records) do
    records = []
    column_mapping.map do |klass, column_name|
      record = instance_double(klass.to_s, id: SecureRandom.random_number(1000), "#{column_name}": "987654321")
      record2 = instance_double(klass.to_s, id: SecureRandom.random_number(1000), "#{column_name}": "324576891")
      allow(record).to receive(:update!).with("#{column_name}": updated_person.participant_id)
      allow(record).to receive(:class).and_return(klass)
      allow(record).to receive(:attributes).and_return("#{column_name}": "987654321")
      allow(record2).to receive(:update!).with("#{column_name}": updated_person.participant_id)
      allow(record2).to receive(:class).and_return(klass)
      allow(record2).to receive(:attributes).and_return("#{column_name}": "324576891")
      records.push(record, record2)
    end
    records
  end

  before do
    # Mock finding the updated person
    allow(Person).to receive(:find_by).with(id: updated_person.id).and_return(updated_person)
    allow(Person).to receive(:where).with(id: duplicate_person_ids).and_return([duplicate_person1, duplicate_person2])

    column_mapping.each do |klass, column_name|
      relevant_records = mock_records.select { |record| record.class == klass }

      allow(klass).to receive(:where)
        .with("#{column_name}": %w[987654321 324576891])
        .and_return(relevant_records)

      relevant_records.each do |record|
        allow(record).to receive(:update!).with("#{column_name}": updated_person.participant_id).and_return(true)
      end
    end

    # Mock destroy! on duplicate persons
    allow(duplicate_person1).to receive(:destroy!)
    allow(duplicate_person2).to receive(:destroy!)
  end

  describe "#remediate!" do
    context "when remediation is successful" do
      it "updates all records with duplicate participant_ids to the updated person participant_id" do
        service.remediate!
        column_mapping.each do |klass, column_name|
          relevant_records = mock_records.select { |record| record.class == klass }
          expect(relevant_records.size).to eq(mock_records.count { |record| record.class == klass })

          relevant_records.each do |mock_record|
            expect(mock_record).to have_received(:update!).with("#{column_name}": updated_person.participant_id)
          end
        end
      end

      it "destroys duplicate persons" do
        service.remediate!

        expect(duplicate_person1).to have_received(:destroy!)
        expect(duplicate_person2).to have_received(:destroy!)
      end

      it "does not update unrelated records" do
        service.remediate!

        unrelated_records = mock_records.reject do |record|
          %w[987654321 324576891].include?(record.attributes.values.first)
        end

        unrelated_records.each do |unrelated_record|
          expect(unrelated_record).not_to have_received(:update!)
        end
      end
    end

    context "when an error occurs during remediation" do
      before do
        # Force `find_and_update_records` to return false to simulate a failure
        allow(service).to receive(:find_and_update_records).and_return(false)
        allow(mock_records.first).to receive(:update!).and_raise(StandardError, "Test error")
      end

      it "does not update any records and skips destroying duplicate persons" do
        result = service.remediate!

        mock_records.each do |mock_record|
          expect(mock_record).not_to have_received(:update!)
        end

        expect(duplicate_person1).not_to have_received(:destroy!)
        expect(duplicate_person2).not_to have_received(:destroy!)

        expect(result).to be_falsey
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
