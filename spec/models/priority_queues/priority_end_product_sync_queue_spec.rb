# frozen_string_literal: true

describe PriorityEndProductSyncQueue, :postgres do
  let!(:record) { create(:priority_end_product_sync_queue) }
  subject { record }

  describe ".not_synced_or_stuck" do
    let!(:synced_record) { create(:priority_end_product_sync_queue, :synced) }
    let!(:stuck_record) { create(:priority_end_product_sync_queue, :stuck) }
    let!(:processing_record) { create(:priority_end_product_sync_queue, :processing) }
    let!(:error_record) { create(:priority_end_product_sync_queue, :error) }
    let!(:preprocessing_record) { create(:priority_end_product_sync_queue, :pre_processing) }

    context "when there is a Priority End Product Sync Queue record with a status of ERROR" do
      it "that record will be returned" do
        expect(PriorityEndProductSyncQueue.not_synced_or_stuck.to_a).to include(error_record)
      end
    end

    context "when there is a Priority End Product Sync Queue record with a status of PROCESSING" do
      it "that record will be returned" do
        expect(PriorityEndProductSyncQueue.not_synced_or_stuck.to_a).to include(processing_record)
      end
    end

    context "when there is a Priority End Product Sync Queue record with a status of PRE_PROCESSING" do
      it "that record will be returned" do
        expect(PriorityEndProductSyncQueue.not_synced_or_stuck.to_a).to include(preprocessing_record)
      end
    end

    context "when there is a Priority End Product Sync Queue record with a status of SYNCED" do
      it "that record will NOT be returned" do
        expect(PriorityEndProductSyncQueue.not_synced_or_stuck.to_a).to_not include(synced_record)
      end
    end

    context "when there is a Priority End Product Sync Queue record with a status of STUCK" do
      it "that record will NOT be returned" do
        expect(PriorityEndProductSyncQueue.not_synced_or_stuck.to_a).to_not include(stuck_record)
      end
    end
  end

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
    let!(:batch_process) { BatchProcessPriorityEpSync.create }

    let!(:stuck_record) do
      create(:priority_end_product_sync_queue,
             error_messages: ["Rspec Testing Error", "Oh No!", "Help I'm Stuck!"],
             batch_id: batch_process.batch_id)
    end

    subject { stuck_record }

    before do
      allow(Raven).to receive(:capture_message)
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

      it "a message will be sent to Sentry" do
        expect(Raven).to have_received(:capture_message)
          .with("StuckRecordAlert::SyncFailed End Product Establishment ID: #{subject.end_product_establishment_id}.",
                extra: {
                  batch_id: subject.batch_id,
                  batch_process_type: subject.batch_process.class.name,
                  caseflow_stuck_record_id: subject.caseflow_stuck_records.first.id,
                  determined_stuck_at: anything,
                  end_product_establishment_id: subject.end_product_establishment_id,
                  queue_type: subject.class.name,
                  queue_id: subject.id
                }, level: "error")
      end
    end
  end

  let!(:end_product_establishment) do
    EndProductEstablishment.create(
      payee_code: "10",
      source_id: 1,
      source_type: "HigherLevelReview",
      veteran_file_number: 1
    )
  end

  let!(:pepsq) do
    PriorityEndProductSyncQueue.create(
      batch_id: nil,
      created_at: Time.zone.now,
      end_product_establishment_id: end_product_establishment.id,
      error_messages: [],
      last_batched_at: nil,
      status: "PRE_PROCESSING"
    )
  end

  describe "#end_product_establishment" do
    it "will return the End Product Establishment object" do
      expect(pepsq.end_product_establishment).to eq(end_product_establishment)
    end
  end
end
