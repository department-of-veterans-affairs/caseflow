# frozen_string_literal: true

require "./app/jobs/batch_processes/batch_process_rescue_job.rb"

describe BatchProcessRescueJob, type: :job do
  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
  end

  let!(:end_product_establishments_one) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records_one) do
    # Changing the duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)
    PopulateEndProductSyncQueueJob.perform_now
  end

  let!(:first_batch_process) do
    # Changing the duration to 0 enables suite to run faster
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0)
    PriorityEpSyncBatchProcessJob.perform_now
  end

  let!(:end_product_establishments_two) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:pepsq_records_two) do
    # Changing the duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)
    PopulateEndProductSyncQueueJob.perform_now
  end

  let!(:second_batch_process) do
    # Changing the duration to 0 enables suite to run faster
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0)
    PriorityEpSyncBatchProcessJob.perform_now
  end

  let!(:batch_process_one) do
    BatchProcess.first
  end

  let!(:batch_process_two) do
    BatchProcess.second
  end

  subject { BatchProcessRescueJob.perform_now }

  describe "#perform" do
    context "when all batch processes are 'COMPLETED'" do
      before do
        subject
      end
      it "all batch processes remain unchanged and do NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
        expect(batch_process_two).to eq(batch_process_two.reload)
      end
    end

    context "when all batch processes are 'COMPLETED' but one has a created_at time more than 12 hours ago" do
      before do
        batch_process_one.update!(created_at: Time.zone.now - 16.hours)
        subject
      end
      it "all batch processes remain unchanged and do NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
        expect(batch_process_two).to eq(batch_process_two.reload)
      end
    end

    context "when a batch process has a state of 'PRE_PROCESSING' & a created_at less than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now - 2.hours)
        subject
      end
      it "the batch process will remain unchanged and will NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
      end
    end

    context "when a batch process has a state of 'PRE_PROCESSING' & a created_at more than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now - 16.hours)
        subject
      end
      it "the batch process will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when a batch process has a state of 'PROCESSING' & a created_at less than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 2.hours)
        subject
      end
      it "the batch process will remain unchanged and will NOT reprocess" do
        expect(batch_process_one).to eq(batch_process_one.reload)
      end
    end

    context "when a batch process has a state of 'PROCESSING' & a created_at more than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 16.hours)
        subject
      end
      it "the batch process will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when two batch processes have a state of 'PRE_PROCESSING' & a created_at more than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now - 16.hours)
        batch_process_two.update!(state: Constants.BATCH_PROCESS.pre_processing, created_at: Time.zone.now - 16.hours)
        subject
      end
      it "both batch processes will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.pre_processing)
        expect(batch_process_two.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when two batch processes have a state of 'PROCESSING' & a created_at more than 12 hours ago" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 16.hours)
        batch_process_two.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 16.hours)
        subject
      end
      it "both batch processes will reprocess" do
        expect(batch_process_one.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_one.reload.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.processing)
        expect(batch_process_two.reload.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when an error occurs during the job" do
      before do
        batch_process_one.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 16.hours)
        batch_process_two.update!(state: Constants.BATCH_PROCESS.processing, created_at: Time.zone.now - 16.hours)
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(BatchProcess).to receive(:needs_reprocessing).and_return([batch_process_one, batch_process_two])
        allow(batch_process_one).to receive(:process_batch!).and_raise(StandardError, "Some unexpected error occured.")
        subject
      end
      it "the error will be logged" do
        # rubocop:disable Layout/LineLength
        expect(Rails.logger).to have_received(:error).with(
          "Error: #<StandardError: Some unexpected error occured.>, Job ID: #{BatchProcessRescueJob::JOB_ATTR.job_id}, Job Time: #{Time.zone.now}"
        )
      end

      it "the error will be sent to Sentry" do
        expect(Raven).to have_received(:capture_exception)
          .with(instance_of(StandardError),
                extra: {
                  job_id: BatchProcessRescueJob::JOB_ATTR.job_id.to_s,
                  job_time: Time.zone.now.to_s
                })
      end

      it "the job will continue after the error and process the next batch until it is completed" do
        expect(batch_process_two.state).to eq(Constants.BATCH_PROCESS.completed)
      end
    end

    context "when there are NO batch processes that need to be reprocessed" do
      before do
        allow(Rails.logger).to receive(:info)
        subject
      end
      it "a message will be logged stating that NO batch processes needed reprocessing" do
        expect(Rails.logger).to have_received(:info).with(
          "No Unfinished Batches Could Be Identified.  Time: #{Time.zone.now}."
        )
      end
    end
  end
end
