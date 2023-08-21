# frozen_string_literal: true

require "./app/jobs/batch_processes/batch_process_rescue_job.rb"

describe BatchProcessRescueJob, type: :job do
  include ActiveJob::TestHelper

  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
    allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
  end

  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  let!(:end_product_establishments_one) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records_one) do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)
    PopulateEndProductSyncQueueJob.perform_now
  end

  let!(:first_batch_process) do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0)
    PriorityEpSyncBatchProcessJob.perform_now
  end

  let!(:end_product_establishments_two) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records_two) do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)
    PopulateEndProductSyncQueueJob.perform_now
  end

  let!(:second_batch_process) do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0)
    PriorityEpSyncBatchProcessJob.perform_now
  end

  let!(:batch_process_one) do
    BatchProcess.first
  end

  let!(:batch_process_two) do
    BatchProcess.second
  end

  subject { @job = BatchProcessRescueJob.perform_later }

  describe "#perform" do
    context "when all batch processes are 'COMPLETED'" do
      before do
        perform_enqueued_jobs do
          subject
        end
      end
      it "all batch processes remain unchanged and do NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
        expect(batch_process_two).to eq(batch_process_two.reload)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when all batch processes are 'COMPLETED' but one has a created_at time more than the ERROR DELAY" do
      before do
        batch_process_one.update!(created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour))
        perform_enqueued_jobs do
          subject
        end
      end
      it "all batch processes remain unchanged and do NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
        expect(batch_process_two).to eq(batch_process_two.reload)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when a batch process has a state of 'PRE_PROCESSING' & a created_at less than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.pre_processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours - 2.hours)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "the batch process will remain unchanged and will NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when a batch process has a state of 'PRE_PROCESSING' & a created_at more than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.pre_processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "the batch process will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when a batch process has a state of 'PROCESSING' & a created_at less than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours - 2.hours)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "the batch process will remain unchanged and will NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when a batch process has a state of 'PROCESSING' & a created_at more than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "the batch process will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when two batch processes have a state of 'PRE_PROCESSING' & a created_at more than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.pre_processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        batch_process_two.update!(
          state: Constants.BATCH_PROCESS.pre_processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "both batch processes will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_two.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when two batch processes have a state of 'PROCESSING' & a created_at more than the ERROR_DELAY" do
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        batch_process_two.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        perform_enqueued_jobs do
          subject
        end
      end
      it "both batch processes will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_two.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when an error occurs during the job" do
      let(:standard_error) { StandardError.new("Some unexpected error occured.") }
      before do
        batch_process_one.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - (BatchProcess::ERROR_DELAY.hours + 1.hour)
        )
        batch_process_two.update!(
          state: Constants.BATCH_PROCESS.processing,
          created_at: Time.zone.now - 16.hours
        )
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(Raven).to receive(:last_event_id) { "sentry_123" }
        allow(BatchProcess).to receive(:needs_reprocessing).and_return([batch_process_one, batch_process_two])
        allow(batch_process_one).to receive(:process_batch!).and_raise(standard_error)
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
                  active_job_id: @job.job_id.to_s,
                  job_time: Time.zone.now.to_s
                })
      end

      it "slack will be notified when job fails" do
        expect(slack_service).to have_received(:send_notification).with(
          "[ERROR] Error running BatchProcessRescueJob.  Error: #{standard_error.message}."\
          "  Active Job ID: #{@job.job_id}.  See Sentry event sentry_123.", "BatchProcessRescueJob"
        )
      end

      it "the job will continue after the error and process the next batch until it is completed" do
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when there are NO batch processes that need to be reprocessed" do
      before do
        allow(Rails.logger).to receive(:info)
        allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
        allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
        perform_enqueued_jobs do
          subject
        end
      end

      it "a message will be logged stating that NO batch processes needed reprocessing" do
        expect(Rails.logger).to have_received(:info).with(
          "No Unfinished Batches Could Be Identified.  Time: #{Time.zone.now}."
        )
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end
  end
end
