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
  ]

  def initialize
    # @logs = ["\nStuck Job Scheduler Processing Log"]
    # @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform

    parent_job_name = self.class


    start_time_parent = @stuck_job_report_service.log_time

    begin
      perform_parent_stuck_job
    rescue StandardError => error
      log_error(error)
    end

    end_time_parent = @stuck_job_report_service.log_time
    @stuck_job_report_service.execution_time(parent_job_name, start_time_parent, end_time_parent)
    # @stuck_job_report_service.write_log_report(REPORT_TEXT)
  end

  def perform_parent_stuck_job
    STUCK_JOBS_ARRAY.each do |job|
      execute_stuck_job(job)
    end
  end

  def execute_stuck_job(stuck_job_class)

    job_name = stuck_job_class

    initial_error_count = StuckJobsErrorCounter.errors_count_for_job(stuck_job_class)

    @stuck_job_report_service.error_count_message(initial_error_count, stuck_job_class)

    start_time = @stuck_job_report_service.log_time
    Rails.logger.info "#{job_name} started."

    begin
      stuck_job_class.perform_now
      Rails.logger.info "#{stuck_job_class} executed successfully."
      final_error_count = StuckJobsErrorCounter.errors_count_for_job(stuck_job_class)
    rescue StandardError => error
      log_error(error)
      Rails.logger.info "#{stuck_job_class} failed to run with error: #{error.message}."
    end

    end_time = @stuck_job_report_service.log_time
    @stuck_job_report_service.execution_time(job_name, start_time, end_time)
    @stuck_job_report_service.error_count_message(final_error_count, stuck_job_class)
    # Continues to next job even if errors occur
  end

  # def log_timing_info(job_name, start_time, end_time)
  #   execution_time = end_time - start_time
  #   message = "#{job_name} executed in #{execution_time} seconds."
  #   @logs.push(message)
  #   Rails.logger.info(message)
  # end

  def upload_logs
    content = @logs.join("\n")
    file_name = "stuck-jobs-profiling-logs/sjp-profiling-log-#{Time.zone.now}"
    S3Service.store_file("#{@folder_name}/#{file_name}", content)
  end
end
