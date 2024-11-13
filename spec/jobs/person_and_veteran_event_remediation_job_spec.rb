# frozen_string_literal: true

RSpec.describe PersonAndVeteranEventRemediationJob, type: :job do
  let(:job) { described_class.new }

  # Mocking external services and data
  let(:event_record_person) do
    instance_double("EventRecord", evented_record_id: 1, evented_record_type: "Person", evented_record: person)
  end
  let(:event_record_veteran) do
    instance_double("EventRecord", evented_record_id: 2, evented_record_type: "Veteran", info: event_info,
                                   evented_record: veteran)
  end

  let(:person) { instance_double("Person", id: 1, ssn: "123456789") }
  let(:person_duplicate) { instance_double("Person", id: 2, ssn: "123456789") }
  let(:veteran) { instance_double("Veteran", id: 2, file_number: "V1234", ssn: "123456789") }

  let(:event_info) { { "before_data" => { "file_number" => "V1234" }, "record_data" => { "file_number" => "V12345" } } }

  # Mocks for remediation services
  let(:duplicate_person_service) { instance_double("Remediations::DuplicatePersonRemediationService") }
  let(:veteran_remediation_service) { instance_double("Remediations::VeteranRecordRemediationService") }

  before do
    allow(RequestStore.store).to receive(:[]=)
    allow(User).to receive(:system_user).and_return(User.new) # Assuming there's a system_user

    # Mocking find_events to return an array with our event_record_person and event_record_veteran
    allow(job).to receive(:find_events).with("Person").and_return([event_record_person])
    allow(job).to receive(:find_events).with("Veteran").and_return([event_record_veteran])

    # Mock Person.where to return duplicates
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
      job.send(:setup_job) # Calling private method directly for test
    end
  end
end
