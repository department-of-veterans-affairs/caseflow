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

  def perform_master_stuck_job_with_profiling
    result = RubyProf.profile do
      begin
        perform_master_stuck_job
      rescue StandardError => error
        log_error(error)
      end
    end

    if result
      flat_printer = RubyProf::FlatPrinter.new(result)
      @logs.push(flat_printer.print)
    else
      @logs.push("Profiling result is nil. There might be an issue during profiling.")
    end

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
      stuck_job_class.new.perform
    rescue StandardError => error
      log_error(error)
    end
  end

  def upload_logs_to_s3
    content = @logs.join("\n")
    file_name = "stuck-jobs-profiling-logs/sjp-profiling-log-#{Time.zone.now}"
    S3Service.store_file("#{@folder_name}/#{file_name}", content)
  end
end
