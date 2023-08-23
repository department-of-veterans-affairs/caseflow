# frozen_string_literal: true

describe PriorityEndProductSyncQueue, :postgres do
  describe ".batchable" do
    before do
      Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
    end

    let!(:pre_processing_batch_process) do
      PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.pre_processing)
    end
    let!(:processing_batch_process) { PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.processing) }
    let!(:completed_batch_process) { PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.completed) }
    let!(:queued_record_never_batched) { create(:priority_end_product_sync_queue, last_batched_at: nil) }
    let!(:queued_record_batched_and_completed) do
      create(:priority_end_product_sync_queue, batch_id: completed_batch_process.batch_id)
    end
    let!(:queued_record_batched_and_processing) do
      create(:priority_end_product_sync_queue, batch_id: processing_batch_process.batch_id)
    end
    let!(:queued_record_batched_and_pre_processing) do
      create(:priority_end_product_sync_queue, batch_id: pre_processing_batch_process.batch_id)
    end

    subject { PriorityEndProductSyncQueue.batchable.to_a }

    it "will return a Priority End Product Sync Queue record that has never been batched" do
      expect(subject).to include(queued_record_never_batched)
    end

    it "will return a Priority End Product Sync Queue record that is tied to a COMPLETED Batch Process" do
      expect(subject).to include(queued_record_batched_and_completed)
    end

    it "will NOT return a Priority End Product Sync Queue record that is tied to a PROCESSING Batch Process" do
      expect(subject).to_not include(queued_record_batched_and_processing)
    end

    it "will NOT return a Priority End Product Sync Queue record that is tied to a PRE_PROCESSING Batch Process" do
      expect(subject).to_not include(queued_record_batched_and_pre_processing)
    end
  end

  describe ".ready_to_batch" do
    before do
      Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
    end

    let!(:queued_record_never_batched) { create(:priority_end_product_sync_queue, last_batched_at: nil) }
    let!(:queued_record_just_batched) { create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now) }
    let!(:queued_record_batched_within_error_delay) do
      create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now - (BatchProcess::ERROR_DELAY - 1).hours)
    end
    let!(:queued_record_batched_after_error_delay) do
      create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now - (BatchProcess::ERROR_DELAY + 1).hours)
    end

    subject { PriorityEndProductSyncQueue.ready_to_batch.to_a }

    it "will return a Priority End Product Sync Queue record that has never been batched" do
      expect(subject).to include(queued_record_never_batched)
    end

    it "will return a Priority End Product Sync Queue record that was batched outside of the ERROR_DELAY" do
      expect(subject).to include(queued_record_batched_after_error_delay)
    end

    it "will NOT return a Priority End Product Sync Queue record that was just batched" do
      expect(subject).to_not include(queued_record_just_batched)
    end

    it "will NOT return a Priority End Product Sync Queue record that was batched within the ERROR_DELAY" do
      expect(subject).to_not include(queued_record_batched_within_error_delay)
    end
  end

  describe ".syncable" do
    let!(:not_processed_record) { create(:priority_end_product_sync_queue) }
    let!(:pre_processing_record) { create(:priority_end_product_sync_queue, :pre_processing) }
    let!(:processing_record) { create(:priority_end_product_sync_queue, :processing) }
    let!(:error_record) { create(:priority_end_product_sync_queue, :error) }
    let!(:synced_record) { create(:priority_end_product_sync_queue, :synced) }
    let!(:stuck_record) { create(:priority_end_product_sync_queue, :stuck) }

    subject { PriorityEndProductSyncQueue.syncable.to_a }

    it "will return a Priority End Product Sync Queue records with a status of NOT_PROCESSED" do
      expect(not_processed_record.status).to eq(Constants.PRIORITY_EP_SYNC.not_processed)
      expect(subject).to include(not_processed_record)
    end

    it "will return a Priority End Product Sync Queue records with a status of PRE_PROCESSING" do
      expect(pre_processing_record.status).to eq(Constants.PRIORITY_EP_SYNC.pre_processing)
      expect(subject).to include(pre_processing_record)
    end

    it "will return a Priority End Product Sync Queue records with a status of PROCESSING" do
      expect(processing_record.status).to eq(Constants.PRIORITY_EP_SYNC.processing)
      expect(subject).to include(processing_record)
    end

    it "will return a Priority End Product Sync Queue records with a status of ERROR" do
      expect(error_record.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      expect(subject).to include(error_record)
    end

    it "will NOT return a Priority End Product Sync Queue records with a status of SYNCED" do
      expect(synced_record.status).to eq(Constants.PRIORITY_EP_SYNC.synced)
      expect(subject).to_not include(synced_record)
    end

    it "will NOT return a Priority End Product Sync Queue records with a status of STUCK" do
      expect(stuck_record.status).to eq(Constants.PRIORITY_EP_SYNC.stuck)
      expect(subject).to_not include(stuck_record)
    end
  end

  describe "#status_processing!" do
    let!(:queued_record) { create(:priority_end_product_sync_queue) }
    it "will update the record's status to PROCESSING" do
      queued_record.status_processing!
      expect(queued_record.status).to eq(Constants.PRIORITY_EP_SYNC.processing)
    end
  end

  describe "#status_sync!" do
    let!(:queued_record) { create(:priority_end_product_sync_queue) }
    it "will update the record's status to SYNCED" do
      queued_record.status_sync!
      expect(queued_record.status).to eq(Constants.PRIORITY_EP_SYNC.synced)
    end
  end

  describe "#status_error!" do
    let!(:queued_record) { create(:priority_end_product_sync_queue) }
    let(:errors) { ["Rspec Testing Error", "Another Error", "Too many errors!"] }

    it "will update the record's status to ERROR" do
      queued_record.status_error!(errors)
      expect(queued_record.status).to eq(Constants.PRIORITY_EP_SYNC.error)
    end

    it "will add the ERROR to error_messages" do
      queued_record.status_error!(errors)
      expect(queued_record.error_messages).to eq(errors)
    end
  end

  describe "#declare_record_stuck" do
    let!(:batch_process) { PriorityEpSyncBatchProcess.create }

    let!(:record) do
      create(:priority_end_product_sync_queue,
             error_messages: ["Rspec Testing Error", "Oh No!", "Help I'm Stuck!"],
             batch_id: batch_process.batch_id)
    end

    subject { record.declare_record_stuck! }

    before do
      allow(Raven).to receive(:capture_message)
      subject
    end

    context "when a record is determined to be stuck" do
      it "the record's status will be updated to STUCK" do
        expect(record.status).to eq(Constants.PRIORITY_EP_SYNC.stuck)
      end

      it "an associated record will be inserted into the caseflow_stuck_records table" do
        found_record = CaseflowStuckRecord.find_by(stuck_record: record)
        expect(record.caseflow_stuck_records).to include(found_record)
      end

      it "a message will be sent to Sentry" do
        expect(Raven).to have_received(:capture_message)
          .with("StuckRecordAlert::SyncFailed End Product Establishment ID: #{record.end_product_establishment_id}.",
                extra: {
                  batch_id: record.batch_id,
                  batch_process_type: record.batch_process.class.name,
                  caseflow_stuck_record_id: record.caseflow_stuck_records.first.id,
                  determined_stuck_at: anything,
                  end_product_establishment_id: record.end_product_establishment_id,
                  queue_type: record.class.name,
                  queue_id: record.id
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

  let!(:batch_process) { PriorityEpSyncBatchProcess.create }

  let!(:pepsq) do
    PriorityEndProductSyncQueue.create(
      batch_id: batch_process.id,
      created_at: Time.zone.now,
      end_product_establishment_id: end_product_establishment.id,
      error_messages: [],
      last_batched_at: nil,
      status: "PRE_PROCESSING"
    )
  end

  let!(:caseflow_stuck_record) do
    CaseflowStuckRecord.create(determined_stuck_at: Time.zone.now,
                               stuck_record: pepsq)
  end

  describe "#end_product_establishment" do
    it "will return the End Product Establishment object" do
      expect(pepsq.end_product_establishment).to eq(end_product_establishment)
    end
  end

  describe "#batch_process" do
    it "will return the Batch Process object" do
      expect(pepsq.batch_process).to eq(batch_process)
    end
  end

  describe "#caseflow_stuck_records" do
    it "will return Caseflow Stuck Record objects" do
      expect(pepsq.caseflow_stuck_records).to include(caseflow_stuck_record)
    end
  end
end
