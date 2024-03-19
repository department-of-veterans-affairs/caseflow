# frozen_string_literal: true

describe Events::CreateVeteranOnEvent do
  let!(:veteran) { create(:veteran) }
  let!(:non_cf_veteran) { double("Veteran", file_number: "12345678X", participant_id: "1826209", bgs_last_synced_at: 1_708_533_584_000, name_suffix: nil, date_of_death: nil) }
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }

  describe "#veteran_exist?" do
    subject { described_class }

    context "when there is no existing Veteran" do
      it "should return false" do
        expect(subject.veteran_exist?("111111111")).to be_falsey
      end
    end

    context "when a Veteran already exists" do
      it "should return true" do
        expect(subject.veteran_exist?(veteran.ssn)).to be_truthy
      end
    end
  end

  describe "#handle_veteran_creation_on_event" do
    subject { described_class }

    context "when creating a new Veteran" do
      it "should create successfully without calling BGS and also create an EventRecord" do
        headers = get_headers
        payload = get_payload
        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new(headers, payload)

        backfilled_veteran = subject.handle_veteran_creation_on_event(event, parser)

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

        expect(event_record.backfill_record).to eq(backfilled_veteran)
      end
    end

    def get_headers
      {
        "X-VA-Vet-SSN" => "123456789",
        "X-VA-File-Number" => "123456789",
        "X-VA-Vet-First-Name" => "John",
        "X-VA-Vet-Last-Name" => "Smith",
        "X-VA-Vet-Middle-Name" => "Alexander"
      }
    end

    def get_payload
      {
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1_708_533_584_000,
          "name_suffix": nil,
          "date_of_death": nil
        }
      }
    end
  end
end
