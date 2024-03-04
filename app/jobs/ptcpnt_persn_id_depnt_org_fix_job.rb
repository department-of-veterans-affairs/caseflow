# frozen_string_literal: true

require_relative "../../lib/helpers/ptcpnt_persn_id_depnt_org_fix.rb"
require_relative "../../lib/helpers/master_scheduler_interface.rb"
class PtcpntPersnIdDepntOrgFixJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def error_text
    "participantPersonId does not match a dependent or an organization"
  end

  def perform
    start_time

    loop_through_and_call_process_records

    end_time
    log_processing_time
  end

  def loop_through_and_call_process_records
    process_records
  end

  def process_records
    fix_instance.start_processing_records
  end

  def records_with_errors
    fix_instance.class.error_records
  end

  def log_processing_time
    (end_time && start_time) ? end_time - start_time : 0
  end

  def start_time
    @start_time ||= Time.zone.now
  end

  def end_time
    @end_time ||= Time.zone.now
  end

  private

  def fix_instance
    @fix_instance ||= PtcpntPersnIdDepntOrgFix.new(@stuck_job_report_service)
  end
end
