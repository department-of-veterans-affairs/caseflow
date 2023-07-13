# frozen_string_literal: true

describe PriorityEndProductSyncQueue, :postgres do
  let!(:record) { create(:priority_end_product_sync_queue) }
  subject { record }

  describe "#status_processing" do
    it "the records status was updated to: PROCESSING" do
      subject.status_processing!
      subject.reload
      expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.processing)
    end
  end

  describe "#status_sync!" do
    it "the records status was updated to: SYNCED" do
      subject.status_sync!
      subject.reload
      expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.synced)
    end
  end

  describe "#status_error!" do
    let(:error_message) { ["Rspec Testing Error"] }

    before do
      subject.status_error!(error_message)
      subject.reload
    end

    context "when a records status is changed to ERROR" do
      it "the records tatus was updated to: ERROR" do
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end

      it "the error that occured was added to error_messages" do
        expect(subject.error_messages).not_to eq({})
      end
    end
  end

  describe "#declare_record_stuck" do
    let(:stuck_record) do
      create(:priority_end_product_sync_queue,
             error_messages: ["Rspec Testing Error", "Oh No!", "Help I'm Stuck!"])
    end

    subject { stuck_record }

    before do
      subject.declare_record_stuck!
      subject.reload
    end

    context "when a record is determined to be stuck" do
      it "the records status was updated to: STUCK" do
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.stuck)
      end

      it "an associated record was created in caseflow_stuck_records" do
        found_record = CaseflowStuckRecord.find_by(stuck_record_id: subject.id)
        expect(found_record).not_to eq(nil)
      end
    end
  end
end
