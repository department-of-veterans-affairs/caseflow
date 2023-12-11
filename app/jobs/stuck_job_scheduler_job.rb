# frozen_string_literal: true

class StuckJobSchedulerJob < CaseflowJob
  # include StuckJobsErrorCounter
  # Sub folder name

  REPORT_TEXT = "Stuck Jobs Profiling Logs"
  STUCK_JOBS_ARRAY = [
    ClaimDateDtFixJob,
    BgsShareErrorFixJob,
    ClaimNotEstablishedFixJob,
    NoAvailableModifiersFixJob,
    PageRequestedByUserFixJob,
    DtaScCreationFailedFixJob,
    ScDtaForAppealFixJob
    # Add stuck jobs here
  ].freeze

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform
    scheduler_job = self.class
    # start_time_parent = @stuck_job_report_service.log_time

    begin
      loop_through_stuck_jobs
      binding.pry
    rescue StandardError => error
      log_error(error)
    end

    # end_time_parent = @stuck_job_report_service.log_time
    # @stuck_job_report_service.execution_time(scheduler_job, start_time_parent, end_time_parent)

    # Send report logs to Slack
    msg = @stuck_job_report_service.logs
    slack_service.send_notification(msg, self.class.to_s)

    # Send report logs to AWS S3
    @stuck_job_report_service.write_log_report(REPORT_TEXT)
    # binding.pry
  end

  def loop_through_stuck_jobs
    STUCK_JOBS_ARRAY.each do |job|
      execute_stuck_job(job)
    end
  end

  def execute_stuck_job(stuck_job_class)
    job_name = stuck_job_class
    job_instance = stuck_job_class.new

    initial_error_count = job_instance::records_with_errors.count

    begin
      job_instance.perform_now

      final_error_count = job_instance::records_with_errors.count
    rescue StandardError => error
      log_error(error)
      Rails.logger.info "#{stuck_job_class} failed to run with error: #{error.message}."
    end

    processing_time = job_instance::log_processing_time
    @stuck_job_report_service.append_job_to_log_table(stuck_job_class, initial_error_count, final_error_count, processing_time)
    # Continues to next job even if errors occur
  end

  def log_processing_time
    (@end_time && @start_time) ? @end_time - @start_time : 0
  end

  def capture_start_time
    @start_time = Time.zone.now
  end

  def capture_end_time
    @end_time = Time.zone.now
  end
end
