# frozen_string_literal: true

require "./app/jobs/batch_processes/batch_process_priority_ep_sync_job.rb"

describe BatchProcessPriorityEpSyncJob, type: :job do
  let!(:syncable_end_product_establishments) do
    create_list(:end_product_establishment, 99, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:end_product_establishment) do
    create(:end_product_establishment, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records) do
    PopulateEndProductSyncQueueJob.perform_now
    PriorityEndProductSyncQueue.all
  end

  subject { BatchProcessPriorityEpSyncJob.perform_now }

  describe "#perform" do
    context "when 99 records can sync successfully and 1 cannot" do
      before do
        end_product_establishment.vbms_ext_claim.destroy!
        subject
      end
      it "the batch process has a state of 'COMPLETED'" do
        expect(BatchProcess.first.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the batch process has a 'started_at' date/time" do
        expect(BatchProcess.first.started_at).not_to be_nil
      end

      it "the batch process has a 'ended_at' date/time" do
        expect(BatchProcess.first.ended_at).not_to be_nil
      end

      it "the batch process has 99 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(syncable_end_product_establishments.count)
      end

      it "the batch process has 1 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(1)
      end
    end

    context "when all 100 records able to sync successfully" do
      before do
        subject
      end
      it "the batch process has a state of 'COMPLETED'" do
        expect(BatchProcess.first.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the batch process has a 'started_at' date/time" do
        expect(BatchProcess.first.started_at).not_to be_nil
      end

      it "the batch process has a 'ended_at' date/time" do
        expect(BatchProcess.first.ended_at).not_to be_nil
      end

      it "the batch process has 100 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(PriorityEndProductSyncQueue.all.count)
      end

      it "the batch process has 0 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(0)
      end
    end

    context "when an error is raised during the job" do
      before do
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(BatchProcessPriorityEpSync).to receive(:find_records).and_raise(StandardError, "Oh no!  This is bad!")
        subject
      end

      it "the error will be logged" do
        expect(Rails.logger).to have_received(:error).with(
          "Error: #<StandardError: Oh no!  This is bad!>,"\
          " Job ID: #{BatchProcessPriorityEpSyncJob::JOB_ATTR.job_id}, Job Time: #{Time.zone.now}"
        )
      end

      it "the error will be sent to Sentry" do
        expect(Raven).to have_received(:capture_exception)
          .with(instance_of(StandardError),
                extra: {
                  job_id: BatchProcessPriorityEpSyncJob::JOB_ATTR.job_id.to_s,
                  job_time: Time.zone.now.to_s
                })
      end
    end

    context "when an there are no records available to batch" do
      before do
        PriorityEndProductSyncQueue.destroy_all
        allow(Rails.logger).to receive(:info)
        subject
      end

      it "a message that says 'No Records Available to Batch' will be logged" do
        expect(Rails.logger).to have_received(:info).with(
          "No Records Available to Batch.  Job ID: #{BatchProcessPriorityEpSyncJob::JOB_ATTR&.job_id}."\
          "  Time: #{Time.zone.now}"
        )
      end
    end
  end
end
