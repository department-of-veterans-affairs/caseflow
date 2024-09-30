# frozen_string_literal: true

require "rails_helper"

describe Events::DecisionReviewUpdated::DecisionReviewUpdatedAudit do
  let(:event) { create(:event) }
  let(:request_issue) { create(:request_issue) }
  let(:update_type) { "I" } # Example update type

  describe "#call" do
    it "creates a new EventRecord with the correct attributes" do
      audit_service = described_class.new(event: event, request_issue: request_issue, update_type: update_type)

      expect { audit_service.call }.to change { EventRecord.count }.by(1)

      event_record = EventRecord.last
      expect(event_record.evented_record).to eq(request_issue)
      expect(event_record.info["update_type"]).to eq(update_type)
      expect(event_record.info["record_data"].except("created_at", "updated_at", "type"))
        .to eq(request_issue.attributes.except("created_at", "updated_at", "type"))
    end

    it "raises an error if EventRecord creation fails" do
      allow(EventRecord).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(EventRecord.new))

      audit_service = described_class.new(event: event, request_issue: request_issue, update_type: update_type)

      expect { audit_service.call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
