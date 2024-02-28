# frozen_string_literal: true

describe Events::CreateVeteranOnEvent do
  let!(:veteran) { create(:veteran) }
  let!(:non_cf_veteran) { double("Veteran", file_number: "12345678X", participant_id: "1826209", bgs_last_synced_at: 1708533584000, name_suffix: nil, date_of_death: nil) }
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }

  describe "#veteran_exist?" do
    subject { described_class}

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

  describe "#create_backfill_veteran" do
    subject { described_class}

    context "when creating a new Veteran" do
      it "should create successfully without calling BGS and also create an EventRecord" do
        headers = get_headers()

        backfilled_veteran = subject.create_backfill_veteran(event, headers, non_cf_veteran)

        expect(backfilled_veteran.ssn).to eq headers["X-VA-Vet-SSN"]
      end
    end

    def get_headers()
      return {
        "X-VA-Vet-SSN" => "123456789",
        "X-VA-File-Number" => "123456789",
        "X-VA-Vet-First-Name" => "John",
        "X-VA-Vet-Last-Name" => "Smith",
        "X-VA-Vet-Middle-Name" => "Alexander"
      }
    end
  end
end
