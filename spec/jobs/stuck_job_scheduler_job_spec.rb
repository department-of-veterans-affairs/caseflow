# frozen_string_literal: true

require Rails.root.join("app", "jobs", "stuck_job_scheduler_job.rb")
require Rails.root.join("lib", "helpers", "stuck_jobs_error_counter.rb")

describe StuckJobSchedulerJob, :postgres do
  let(:stuck_job_report_service) { instance_double("StuckJobReportService") }
  let(:claim_date_dt_error) { "ClaimDateDt" }
  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_date_dt_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
  end


  subject { described_class.new }

  before do
    # allow(StuckJobReportService).to receive(:new).and_return(stuck_job_report_service)
    allow(stuck_job_report_service).to receive(:log_time).and_return(Time.zone.now)
  end

  describe "#perform" do

    it 'executes the job and updates the error count' do
      allow(StuckJobReportService).to receive(:new).and_return(stuck_job_report_service)
      # expect(StuckJobReportService).to receive(:append_record_count).with(1, claim_date_dt_error)

      subject.perform
    end
    it "executes perform_parent_stuck_job" do
      current_time = Time.zone.now
      # expect(subject).to receive(:perform_parent_stuck_job)

      expect(stuck_job_report_service).to receive(:execution_time) do |job, start_time, end_time|
        expect(job).to eq(StuckJobSchedulerJob)
        expect(start_time).to be_within(1.second).of(current_time)
        expect(end_time).to be_within(1.second).of(current_time)

        expect(stuck_job_report_service).to receive(:logs)
        expect(stuck_job_report_service).to receive(:write_log_report)
      end

      subject.perform
    end
  end

  describe "#perform_parent_stuck_job" do
    it "executes execute_stuck_job for each job in STUCK_JOBS_ARRAY" do
      StuckJobSchedulerJob::STUCK_JOBS_ARRAY.each do |job_class|
        expect(subject).to receive(:execute_stuck_job).with(job_class)
      end

      subject.loop_through_stuck_jobs
    end
  end

  describe "#execute_stuck_job" do
    let(:stuck_job_class) { ClaimDateDtFixJob }

    before do
      allow(Rails.logger).to receive(:info)
      allow(stuck_job_report_service).to receive(:error_count_message)
      allow(stuck_job_report_service).to receive(:execution_time)
      allow(stuck_job_report_service).to receive(:append_dividier)
    end

    it "executes perform_now on the child job class" do
      initial_error_count = 1 # Set the initial error count as needed for your test
      allow(StuckJobsErrorCounter).to receive(:errors_count_for_job).and_return(initial_error_count)
      expect(Rails.logger).to receive(:info).with("#{stuck_job_class} started.")

      # Assuming perform_now raises an error
      allow(stuck_job_class).to receive(:perform_now).and_raise(StandardError, "SomeError")

      expect(Rails.logger).to receive(:info).with("#{stuck_job_class} failed to run with error: SomeError.")
      subject.execute_stuck_job(stuck_job_class)
    end

    it "logs error count and execution time" do
      allow(stuck_job_class).to receive(:perform_now)

      expect(stuck_job_report_service).to receive(:error_count_message).twice
      expect(stuck_job_report_service).to receive(:execution_time).once

      subject.execute_stuck_job(stuck_job_class)
    end
  end
end
