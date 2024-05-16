# frozen_string_literal: true

require "./app/jobs/batch_processes/priority_ep_sync_batch_process_job.rb"
require "./app/models/batch_processes/batch_process.rb"

describe PriorityEpSyncBatchProcessJob, type: :job do
  include ActiveJob::TestHelper

  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
  end

  let!(:syncable_end_product_establishments) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:end_product_establishment) do
    create(:end_product_establishment, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records) do
    PriorityEndProductSyncQueue.all
  end

  subject do
    PriorityEpSyncBatchProcessJob.perform_later
  end

  describe "#perform" do
    context "when 2 records can sync successfully and 1 cannot" do
      before do
        end_product_establishment.vbms_ext_claim.destroy!
        perform_enqueued_jobs do
          subject
        end
      end

      it "creates one batch process record" do
        expect(BatchProcess.count).to eq(1)
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

      it "the batch process has 2 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(2)
      end

      it "the batch process has 1 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(1)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when all 3 records able to sync successfully" do
      before do
        perform_enqueued_jobs do
          subject
        end
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

      it "the batch process has 3 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(3)
      end

      it "the batch process has 0 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(0)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when the job creates multiple batches" do
      before do
        # Batch limit changes to 1 to test PriorityEpSyncBatchProcessJob loop
        stub_const("BatchProcess::BATCH_LIMIT", 1)

        PriorityEndProductSyncQueue.last.destroy!
        perform_enqueued_jobs do
          subject
        end
      end

      it "both batch processes have a state of 'COMPLETED'" do
        expect(BatchProcess.first.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(BatchProcess.second.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "both batch processes have a 'started_at' date/time" do
        expect(BatchProcess.first.started_at).not_to be_nil
        expect(BatchProcess.second.started_at).not_to be_nil
      end

      it "both batch processes have a 'ended_at' date/time" do
        expect(BatchProcess.first.ended_at).not_to be_nil
        expect(BatchProcess.second.ended_at).not_to be_nil
      end

      it "the first batch process has 1 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(BatchProcess::BATCH_LIMIT)
      end

      it "the second batch process has 1 records_completed" do
        expect(BatchProcess.second.records_completed).to eq(BatchProcess::BATCH_LIMIT)
      end

      it "both batch processes have 0 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(0)
        expect(BatchProcess.second.records_failed).to eq(0)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when the job duration ends before all PriorityEndProductSyncQueue records can be batched" do
      before do
        # Batch limit of 1 limits the number of priority end product sync queue records per batch
        stub_const("BatchProcess::BATCH_LIMIT", 1)
        # Job duration of 0.01 seconds limits the job's loop to one iteration
        stub_const("PriorityEpSyncBatchProcessJob::JOB_DURATION", 0.01.seconds)

        PriorityEndProductSyncQueue.last.destroy!
        perform_enqueued_jobs do
          subject
        end
      end

      it "only 1 batch process record is created" do
        expect(BatchProcess.count).to eq(1)
      end

      it "the batch process syncs & deletes only 1 of the 2 available PriorityEndProductSyncQueue records" do
        expect(PriorityEndProductSyncQueue.count).to eq(1)
        expect(BatchProcess.first.priority_end_product_sync_queue.count).to eq(0)
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

      it "the batch process has 1 records_attempted" do
        expect(BatchProcess.first.records_attempted).to eq(1)
      end

      it "the batch process has 0 records_failed" do
        expect(BatchProcess.first.records_failed).to eq(0)
      end

      it "the batch process has 1 records_completed" do
        expect(BatchProcess.first.records_completed).to eq(1)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when an error is raised during the job" do
      let(:standard_error) { StandardError.new("Oh no!  This is bad!") }
      before do
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(Raven).to receive(:last_event_id) { "sentry_123" }
        allow(PriorityEpSyncBatchProcess).to receive(:find_records_to_batch)
          .and_raise(StandardError, "Oh no!  This is bad!")
        perform_enqueued_jobs do
          subject
        end
      end

      it "the error and the backtrace will be logged" do
        expect(Rails.logger).to have_received(:error).with(an_instance_of(StandardError))
      end

      it "the error will be sent to Sentry" do
        expect(Raven).to have_received(:capture_exception)
          .with(instance_of(StandardError),
                extra: {
                  job_id: subject.job_id,
                  job_time: Time.zone.now.to_s
                })
      end

      it "slack will be notified when job fails" do
        expect(slack_service).to have_received(:send_notification).with(
          "[ERROR] Error running PriorityEpSyncBatchProcessJob.  Error: #{standard_error.message}."\
          "  Active Job ID: #{subject.job_id}.  See Sentry event sentry_123.", "PriorityEpSyncBatchProcessJob"
        )
      end
    end

    context "when there are no records available to batch" do
      before do
        PriorityEndProductSyncQueue.destroy_all
        allow(Rails.logger).to receive(:info)
        perform_enqueued_jobs do
          subject
        end
      end

      it "a message that says 'Cannot Find Any Records to Batch' will be logged" do
        expect(Rails.logger).to have_received(:info).with(
          "PriorityEpSyncBatchProcessJob Cannot Find Any Records to Batch."\
          "  Job will be enqueued again at the top of the hour."\
          "  Active Job ID: #{subject.job_id}.  Time: #{Time.zone.now}"
        )
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end
  end
end
