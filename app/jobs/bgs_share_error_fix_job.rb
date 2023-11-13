# frozen_string_literal: true

class BgsShareErrorFixJob < CaseflowJob
  queue_with_priority :low_priority

  ERROR_TEXT = "ShareError"

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform
    RequestStore[:current_user] = User&.system_user
    clear_hlr_errors if hlrs_with_errors.present?
    clear_rius_errors if rius_with_errors.present?
    clear_bge_errors if bges_with_errors.present?
    @stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def clear_rius_errors
    @stuck_job_report_service.append_record_count(rius_with_errors.count, ERROR_TEXT)
    rius_with_errors.each do |riu|
      epe = EndProductEstablishment.find_by(
        id: riu.review_id
      )
      next if epe.established_at.blank?

      resolve_error_on_records(riu)
      @stuck_job_report_service.append_single_record(riu.class.name, riu.id)
    end
    @stuck_job_report_service.append_record_count(rius_with_errors.count, ERROR_TEXT)
  end

  def clear_hlr_errors
    @stuck_job_report_service.append_record_count(hlrs_with_errors.count, ERROR_TEXT)

    hlrs_with_errors.each do |hlr|
      epe = EndProductEstablishment.find_by(
        veteran_file_number: hlr.veteran_file_number
      )
      next if epe.established_at.blank?

      resolve_error_on_records(hlr)
      @stuck_job_report_service.append_single_record(hlr.class.name, hlr.id)
    end
    @stuck_job_report_service.append_record_count(hlrs_with_errors.count, ERROR_TEXT)
  end

  def clear_bge_errors
    @stuck_job_report_service.append_record_count(bges_with_errors.count, ERROR_TEXT)

    bges_with_errors.each do |bge|
      next if bge.end_product_establishment.established_at.blank?

      resolve_error_on_records(bge)
      @stuck_job_report_service.append_single_record(bge.class.name, bge.id)
    end
    @stuck_job_report_service.append_record_count(bges_with_errors.count, ERROR_TEXT)
  end

  def hlrs_with_errors
    HigherLevelReview.where("establishment_error ILIKE?", "%#{ERROR_TEXT}%")
  end

  def rius_with_errors
    RequestIssuesUpdate.where("error ILIKE?", "%#{ERROR_TEXT}%")
  end

  def bges_with_errors
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%#{ERROR_TEXT}%")
  end

  private

  # :reek:FeatureEnvy
  def resolve_error_on_records(object_type)
    ActiveRecord::Base.transaction do
      object_type.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
    end
  end
end
