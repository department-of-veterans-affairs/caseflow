# frozen_string_literal: true

require "./app/models/batch_processes/batch_process.rb"

describe BatchProcess, :postgres do
  describe ".needs_reprocessing" do
    before do
      Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
    end

    let!(:pre_processing_batch_process_within_error_delay) do
      PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now)
    end
    let!(:pre_processing_batch_process_outside_error_delay) do
      PriorityEpSyncBatchProcess.create(
        state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now - (BatchProcess::ERROR_DELAY + 1).hours
      )
    end
    let!(:processing_batch_process_within_error_delay) do
      PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now)
    end
    let!(:processing_batch_process_outside_error_delay) do
      PriorityEpSyncBatchProcess.create(
        state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - (BatchProcess::ERROR_DELAY + 1).hours
      )
    end
    let!(:completed_batch_process_within_error_delay) do
      PriorityEpSyncBatchProcess.create(state: Constants.BATCH_PROCESS.completed, created_at: Time.zone.now)
    end
    let!(:completed_batch_process_outside_error_delay) do
      PriorityEpSyncBatchProcess.create(
        state: Constants.BATCH_PROCESS.completed, created_at: Time.zone.now - (BatchProcess::ERROR_DELAY + 1).hours
      )
    end

    subject { BatchProcess.needs_reprocessing.to_a }

    it "will return Batch Processes that have a state of PRE_PROCESSING and a created_at outside of the error_delay" do
      expect(subject).to include(pre_processing_batch_process_outside_error_delay)
    end

    it "will return Batch Processes that have a state of PROCESSING and a created_at outside of the error_delay" do
      expect(subject).to include(processing_batch_process_outside_error_delay)
    end

    it "will NOT return Batch Processes that have a state of PRE_PROCESSING and a created_at within the error_delay" do
      expect(subject).to_not include(pre_processing_batch_process_within_error_delay)
    end

    it "will NOT return Batch Processes that have a state of PROCESSING and a created_at within the error_delay" do
      expect(subject).to_not include(processing_batch_process_within_error_delay)
    end

    it "will NOT return Batch Processes that have a state of COMPLETED and a created_at outside of the error_delay" do
      expect(subject).to_not include(completed_batch_process_outside_error_delay)
    end

    it "will NOT return Batch Processes that have a state of COMPLETED and a created_at within the error_delay" do
      expect(subject).to_not include(completed_batch_process_within_error_delay)
    end
  end

  describe ".find_records_to_batch" do
    it "is a no-op method that does nothing and returns nil" do
      expect(BatchProcess.find_records_to_batch).to eq(nil)
    end
  end

  describe ".create_batch!(_records)" do
    it "is a no-op method that does nothing and returns nil" do
      expect(BatchProcess.create_batch!(nil)).to eq(nil)
    end
  end

  describe "#process_batch!" do
    let!(:batch_process) { BatchProcess.new }
    it "is a no-op method that does nothing" do
    end
  end

  describe "#increment_completed" do
    let(:batch) { BatchProcess.new }

    it "will increment @completed_count by 1" do
      batch.send(:increment_completed)
      expect(batch.instance_variable_get(:@completed_count)).to eq(1)
    end
  end

  describe "#increment_failed" do
    let(:batch) { BatchProcess.new }

    it "will increment @failed_count by 1" do
      batch.send(:increment_failed)
      expect(batch.instance_variable_get(:@failed_count)).to eq(1)
    end
  end

  describe "#batch_processing!" do
    let(:batch) { PriorityEpSyncBatchProcess.new }

    before do
      Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
    end

    it "will update the Batch Process state to PROCESSING" do
      batch.send(:batch_processing!)
      expect(batch.state).to eq(Constants.BATCH_PROCESS.processing)
    end

    it "will update started_at to the current date/time" do
      batch.send(:batch_processing!)
      expect(batch.started_at).to eq(Time.zone.now)
    end
  end

  describe "#batch_complete!" do
    let(:batch) { PriorityEpSyncBatchProcess.new }

    before do
      Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
      batch.instance_variable_set(:@completed_count, 1)
      batch.instance_variable_set(:@failed_count, 1)
    end

    it "will update the Batch Process state to COMPLETED" do
      batch.send(:batch_complete!)
      expect(batch.state).to eq(Constants.BATCH_PROCESS.completed)
    end

    it "will update the Batch Process records_completed" do
      batch.send(:batch_complete!)
      expect(batch.records_failed).to eq(batch.instance_variable_get(:@completed_count))
    end

    it "will update the Batch Process records_failed" do
      batch.send(:batch_complete!)
      expect(batch.records_failed).to eq(batch.instance_variable_get(:@failed_count))
    end

    it "will update ended_at to the current date/time" do
      batch.send(:batch_complete!)
      expect(batch.ended_at).to eq(Time.zone.now)
    end
  end

  describe "#error_out_record!(record, error)" do
    let(:batch) { BatchProcess.new }
    let!(:record) { create(:priority_end_product_sync_queue) }
    let(:error) { "Rspec Test Error" }
    subject { record }

    context "when a record encounters an error" do
      it "a new error message is added to error_messages" do
        batch.send(:error_out_record!, subject, error)
        subject.reload
        expect(subject.error_messages.count).to eq(1)
      end

      it "the record is inspected to see if it's STUCK" do
        batch.send(:error_out_record!, subject, error + " 1")
        batch.send(:error_out_record!, subject, error + " 2")
        batch.send(:error_out_record!, subject, error + " 3")
        subject.reload
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.stuck)
      end

      it "status is changed to ERROR" do
        batch.send(:error_out_record!, subject, error)
        subject.reload
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end
    end
  end
end
