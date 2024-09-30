# frozen_string_literal: true

require "rails_helper"

describe Events::DecisionReviewUpdated::DecisionReviewUpdatedAudit do
  let(:event) { create(:event) }
  let(:request_issue) { create(:request_issue) }
  let(:parser) { double(Events::DecisionReviewUpdated::DecisionReviewUpdatedParser) }

  before do
    allow(parser).to receive(:updated_issues).and_return([])
    allow(parser).to receive(:added_issues).and_return([])
    allow(parser).to receive(:removed_issues).and_return([])
    allow(parser).to receive(:ineligible_to_eligible_issues).and_return([])
    allow(parser).to receive(:eligible_to_ineligible_issues).and_return([])
    allow(parser).to receive(:ineligible_to_ineligible_issues).and_return([])
  end

  before do
    request_issue.update(reference_id: "1234567890")
    request_issue.reload
  end

  describe "#call" do
    it "creates an event record for updated request issues" do
      allow(parser).to receive(:updated_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
      expect(event_record.info["update_type"]).to eq("U")
    end

    it "creates an event record for added request issues" do
      allow(parser).to receive(:added_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end

    it "creates an event record for removed request issues" do
      allow(parser).to receive(:removed_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end

    it "creates an event record for ineligible to eligible request issues" do
      allow(parser).to receive(:ineligible_to_eligible_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end

    it "creates an event record for eligible to ineligible request issues" do
      allow(parser).to receive(:eligible_to_ineligible_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end

    it "creates an event record for ineligible to ineligible request issues" do
      allow(parser).to receive(:ineligible_to_ineligible_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end

    it "creates an event record for withdrawn request issues" do
      allow(parser).to receive(:withdrawn_issues).and_return([{ reference_id: "1234567890" }])

      audit_service = described_class.new(event: event, parser: parser)

      expect { audit_service.call! }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
    end
  end
end
