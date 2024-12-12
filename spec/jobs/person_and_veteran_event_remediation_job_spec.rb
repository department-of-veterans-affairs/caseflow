# frozen_string_literal: true

RSpec.describe PersonAndVeteranEventRemediationJob, type: :job do
  let(:job) { described_class.new }

  let!(:event) { PersonUpdatedEvent.create!(reference_id: "1") } # Create an event

  let(:person) { Person.create!(id: 1, ssn: "123456789", participant_id: "456789123") }
  let(:person_duplicate) { Person.create!(id: 2, ssn: "123456789", participant_id: "987654321") }
  let(:veteran) { Veteran.create!(id: 2, ssn: "123456789", file_number: "V1234") }

  let(:event_info) { { "before_data" => { "file_number" => "V1234" }, "record_data" => { "file_number" => "V12345" } } }

  let(:event_record_person) do
    EventRecord.create!(evented_record_id: person.id, evented_record_type: "Person", event: event,
                        evented_record: person)
  end
  let(:event_record_veteran) do
    EventRecord.create!(evented_record_id: veteran.id, evented_record_type: "Veteran", info: event_info,
                        event: event, evented_record: veteran)
  end

  # Mocks for remediation services
  let(:duplicate_person_service) { instance_double("Remediations::DuplicatePersonRemediationService") }
  let(:veteran_remediation_service) { instance_double("Remediations::VeteranRecordRemediationService") }

  before do
    allow(RequestStore.store).to receive(:[]=)
    allow(User).to receive(:system_user).and_return(User.new)

    # Mocking find_events to return an array with our event_record_person and event_record_veteran
    allow(job).to receive(:find_events).with("Person").and_return([event_record_person])
    allow(job).to receive(:find_events).with("Veteran").and_return([event_record_veteran])

    # Mock Person.where to return duplicates
    allow(EventRecord).to receive(:where).and_call_original
    allow(Person).to receive(:where).with(ssn: "123456789").and_return([person, person_duplicate])
    allow(Veteran).to receive(:where).with(ssn: "123456789").and_return([veteran])

    allow(Remediations::DuplicatePersonRemediationService).to receive(:new).and_return(duplicate_person_service)
    allow(duplicate_person_service).to receive(:remediate!)
    allow(Remediations::VeteranRecordRemediationService).to receive(:new).and_return(veteran_remediation_service)
    allow(veteran_remediation_service).to receive(:remediate!)
  end

  describe "#perform" do
    context "when processing Person events" do
      it "calls remediation service if duplicate persons are found" do
        expect(duplicate_person_service).to receive(:remediate!)
        job.perform
      end

      it "does not call remediation service if no duplicates are found" do
        # Modify the mock to return only the original person
        allow(Person).to receive(:where).with(ssn: "123456789").and_return([person])
        expect(duplicate_person_service).not_to receive(:remediate!)
        expect(event_record_person).to receive(:processed!)
        job.perform
      end
    end

    context "when processing Veteran events" do
      it "calls remediation service if file_number differs" do
        expect(veteran_remediation_service).to receive(:remediate!)
        job.perform
      end

      it "does not call remediation service if file_number is the same" do
        # Modify event_info to make file numbers match
        allow(event_record_veteran).to receive(:info)
          .and_return({ "before_data" => { "file_number" => "V1234" }, "record_data" => { "file_number" => "V1234" } })
        expect(veteran_remediation_service).not_to receive(:remediate!)
        job.perform
      end
    end
  end

  describe "#setup_job" do
    it "sets current_user in the RequestStore" do
      expect(RequestStore.store).to receive(:[]=).with(:current_user, User.system_user)
      job.send(:setup_job)
    end
  end
end
