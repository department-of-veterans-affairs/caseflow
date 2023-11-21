# frozen_string_literal: true

require "ruby-prof"

class StuckJobSchedulerJob < CaseflowJob
  # Sub folder name
  S3_FOLDER_NAME = "data-remediation-output"

  def initialize
    @logs = ["\nStuck Job Scheduler Profiling Log"]
    @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
    super
  end

  def perform
    start_time_master = Time.zone.now

    begin
      perform_master_stuck_job
    rescue StandardError => error
      log_error(error)
    end

    end_time_master = Time.zone.now
    log_timing_info(self.class, start_time_master, end_time_master)
    upload_logs
  end

  def perform_master_stuck_job
    execute_stuck_job(ClaimDateDtFixJob)
    execute_stuck_job(BgsShareErrorFixJob)
    execute_stuck_job(ClaimNotEstablishedFixJob)
    execute_stuck_job(NoAvailableModifiersFixJob)
    execute_stuck_job(PageRequestedByUserFixJob)
    execute_stuck_job(ScDtaForAppealFixJob)
    execute_stuck_job(DtaScCreationFailedFixJob)
    # Add additional stuck jobs here
  end

  def execute_stuck_job(stuck_job_class)
    begin
      child_job_name = stuck_job_class.name
      start_time = Time.zone.now

      stuck_job_class.perform_later

      end_time = Time.zone.now
      log_timing_info(child_job_name, start_time, end_time)
    rescue StandardError => error
      log_error(error)
    end
  end

  def log_timing_info(job_name, start_time, end_time)
    execution_time = end_time - start_time
    message = "#{job_name} exectued in #{execution_time} seconds."
    @log.push(message)
    Rails.logger.info(message)
  end

  def upload_logs
    content = @logs.join("\n")
    file_name = "stuck-jobs-profiling-logs/sjp-profiling-log-#{Time.zone.now}"
    S3Service.store_file("#{@folder_name}/#{file_name}", content)
  end
end
