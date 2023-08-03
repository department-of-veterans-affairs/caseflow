# frozen_string_literal: true

require "./app/jobs/batch_processes/priority_ep_sync_batch_process_job.rb"
require "./app/models/batch_processes/batch_process.rb"

describe PriorityEpSyncBatchProcessJob, type: :job do
  let!(:syncable_end_product_establishments) do
    create_list(:end_product_establishment, 99, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:end_product_establishment) do
    create(:end_product_establishment, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records) do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)

    PopulateEndProductSyncQueueJob.perform_now
    PriorityEndProductSyncQueue.all
  end

  subject do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0)
    # Batch limit changes to 50 to test PriorityEpSyncBatchProcessJob loop
    stub_const("BatchProcess::BATCH_LIMIT", 50)

    PriorityEpSyncBatchProcessJob.perform_now
  end

  describe "#perform" do
    context "when 99 records can sync successfully and 1 cannot" do
      before do
        end_product_establishment.vbms_ext_claim.destroy!
        subject
      end

      let(:first_batch_process) do
        bp1 = BatchProcess.first
        bp2 = BatchProcess.second

        (bp1.created_at < bp2.created_at) ? bp1 : bp2
      end

      let(:second_batch_process) do
        bp1 = BatchProcess.first
        bp2 = BatchProcess.second

        (bp1.created_at > bp2.created_at) ? bp1 : bp2
      end

      it "creates two batch process records" do
        expect(BatchProcess.count).to eq(2)
      end

      it "both batch processes have a state of 'COMPLETED'" do
        expect(first_batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(second_batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "both batch processes have a 'started_at' date/time" do
        expect(first_batch_process.started_at).not_to be_nil
        expect(second_batch_process.started_at).not_to be_nil
      end

      it "both batch processes have a 'ended_at' date/time" do
        expect(first_batch_process.ended_at).not_to be_nil
        expect(second_batch_process.ended_at).not_to be_nil
      end

      it "the first batch process has 49 records_completed" do
        expect(first_batch_process.records_completed).to eq(49)
      end

      it "the second batch process has 50 records_completed" do
        expect(second_batch_process.records_completed).to eq(50)
      end

      it "the first batch process has 1 records_failed" do
        expect(first_batch_process.records_failed).to eq(1)
      end

      it "the second batch process has 0 records_failed" do
        expect(second_batch_process.records_failed).to eq(0)
      end
    end

    context "when all 100 records able to sync successfully" do
      before do
        subject
      end

      let!(:first_batch_process) do
        bp1 = BatchProcess.first
        bp2 = BatchProcess.second

        (bp1.created_at < bp2.created_at) ? bp1 : bp2
      end

      let!(:second_batch_process) do
        bp1 = BatchProcess.first
        bp2 = BatchProcess.second

        (bp1.created_at > bp2.created_at) ? bp1 : bp2
      end

      it "both batch processes have a state of 'COMPLETED'" do
        expect(first_batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(second_batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "both batch processes have a 'started_at' date/time" do
        expect(first_batch_process.started_at).not_to be_nil
        expect(second_batch_process.started_at).not_to be_nil
      end

      it "both batch processes have a 'ended_at' date/time" do
        expect(first_batch_process.ended_at).not_to be_nil
        expect(second_batch_process.ended_at).not_to be_nil
      end

      it "the first batch process has 50 records_completed" do
        expect(first_batch_process.records_completed).to eq(BatchProcess::BATCH_LIMIT)
      end

      it "the second batch process has 50 records_completed" do
        expect(second_batch_process.records_completed).to eq(BatchProcess::BATCH_LIMIT)
      end

      it "both batch processes have 0 records_failed" do
        expect(first_batch_process.records_failed).to eq(0)
        expect(second_batch_process.records_failed).to eq(0)
      end
    end

    context "when an error is raised during the job" do
      before do
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(PriorityEpSyncBatchProcess).to receive(:find_records_to_batch)
          .and_raise(StandardError, "Oh no!  This is bad!")
        subject
      end

      it "the error will be logged" do
        expect(Rails.logger).to have_received(:error).with(
          "Error: #<StandardError: Oh no!  This is bad!>,"\
          " Job ID: #{PriorityEpSyncBatchProcessJob::JOB_ATTR.job_id}, Job Time: #{Time.zone.now}"
        )
      end

      it "the error will be sent to Sentry" do
        expect(Raven).to have_received(:capture_exception)
          .with(instance_of(StandardError),
                extra: {
                  job_id: PriorityEpSyncBatchProcessJob::JOB_ATTR.job_id.to_s,
                  job_time: Time.zone.now.to_s
                })
      end
    end

    context "when there are no records available to batch" do
      before do
        PriorityEndProductSyncQueue.destroy_all
        allow(Rails.logger).to receive(:info)
        subject
      end

      it "a message that says 'No Records Available to Batch' will be logged" do
        expect(Rails.logger).to have_received(:info).with(
          "No Records Available to Batch.  Job will be enqueued again once 1-hour mark is hit.  Job ID: #{PriorityEpSyncBatchProcessJob::JOB_ATTR&.job_id}."\
          "  Time: #{Time.zone.now}"
        )
      end
    end
  end
end
