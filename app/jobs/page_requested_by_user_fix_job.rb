# frozen_string_literal: true

class PageRequestedByUserFixJob < CaseflowJob
  ERROR_TEXT = "Page requested by the user is unavailable"

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
  end

  def perform
    clear_bge_errors if bges_with_errors.present?
  end

  # :reek:FeatureEnvy
  def resolve_error_on_records(object_type)
    object_type.clear_error!
  rescue StandardError => error
    log_error(error)
    stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
  end

  def clear_bge_errors
    stuck_job_report_service.append_record_count(bges_with_errors.count, ERROR_TEXT)

    bges_with_errors.each do |bge|
      next if bge.end_product_establishment.established_at.blank?

      resolve_error_on_records(bge)
      stuck_job_report_service.append_single_record(bge.class.name, bge.id)
    end
    stuck_job_report_service.append_record_count(bges_with_errors.count, ERROR_TEXT)
  end

  def bges_with_errors
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%#{ERROR_TEXT}%")
  end
end
