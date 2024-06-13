# frozen_string_literal: true

# rubocop:disable Layout/LineLength

describe Events::CreateVeteranOnEvent do
  let!(:veteran) { create(:veteran) }
  let!(:non_cf_veteran) { double("Veteran", file_number: "12345678X", participant_id: "1826209", bgs_last_synced_at: 1_708_533_584_000, name_suffix: nil, date_of_death: nil) }
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example }

  describe "#veteran_exist?" do
    subject { described_class }

    context "when there is no existing Veteran" do
      it "should return false" do
        expect(subject.veteran_exist?("111111111")).to be_falsey
      end
    end

    context "when a Veteran already exists" do
      it "should return true" do
        expect(subject.veteran_exist?(veteran.file_number)).to be_truthy
      end
    end
  end

  describe "#handle_veteran_creation_on_event" do
    subject { described_class }

    context "when creating a new Veteran" do
      it "should create successfully without calling BGS and also create an EventRecord" do
        headers = retrieve_headers

        backfilled_veteran = subject.handle_veteran_creation_on_event(event: event, parser: parser)

        expect(backfilled_veteran.ssn).to eq headers["X-VA-Vet-SSN"]
        expect(backfilled_veteran.file_number).to eq headers["X-VA-File-Number"]
        expect(backfilled_veteran.first_name).to eq headers["X-VA-Vet-First-Name"]
        expect(backfilled_veteran.last_name).to eq headers["X-VA-Vet-Last-Name"]
        expect(backfilled_veteran.middle_name).to eq headers["X-VA-Vet-Middle-Name"]

        expect(backfilled_veteran.participant_id).to eq non_cf_veteran.participant_id
        expect(backfilled_veteran.bgs_last_synced_at).to eq parser.convert_milliseconds_to_datetime(non_cf_veteran.bgs_last_synced_at)
        expect(backfilled_veteran.name_suffix).to eq nil
        expect(backfilled_veteran.date_of_death).to eq nil

        expect(EventRecord.count).to eq 1
        event_record = EventRecord.first

        expect(event_record.evented_record).to eq(backfilled_veteran)
      end

      it "should create veteran without middle name" do
        headers = retrieve_headers
        parser.headers["X-VA-Vet-Middle-Name"] = ""
        backfilled_veteran = subject.handle_veteran_creation_on_event(event: event, parser: parser)

        expect(backfilled_veteran.ssn).to eq headers["X-VA-Vet-SSN"]
        expect(backfilled_veteran.file_number).to eq headers["X-VA-File-Number"]
        expect(backfilled_veteran.first_name).to eq headers["X-VA-Vet-First-Name"]
        expect(backfilled_veteran.last_name).to eq headers["X-VA-Vet-Last-Name"]
        expect(backfilled_veteran.middle_name).to eq nil

        expect(backfilled_veteran.participant_id).to eq non_cf_veteran.participant_id
        expect(backfilled_veteran.bgs_last_synced_at).to eq parser.convert_milliseconds_to_datetime(non_cf_veteran.bgs_last_synced_at)
        expect(backfilled_veteran.name_suffix).to eq nil
        expect(backfilled_veteran.date_of_death).to eq nil

        expect(EventRecord.count).to eq 1
        event_record = EventRecord.first

        expect(event_record.evented_record).to eq(backfilled_veteran)
      end
    end

    def retrieve_headers
      {
        "X-VA-Vet-SSN" => "123456789",
        "X-VA-File-Number" => "77799777",
        "X-VA-Vet-First-Name" => "John",
        "X-VA-Vet-Last-Name" => "Smith",
        "X-VA-Vet-Middle-Name" => "Alexander"
      }
    end
  end
end

# rubocop:enable Layout/LineLength
