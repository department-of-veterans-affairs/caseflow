# frozen_string_literal: true

class BgsShareErrorFixJob < CaseflowJob
  ERROR_TEXT = "ShareError"
  STUCK_JOB_REPORT_SERVICE = StuckJobReportService.new

  def perform
    clear_hlr_errors if hlrs_with_errors.present?
    clear_rius_errors if rius_with_errors.present?
    clear_bge_errors if bges_with_errors.present?
  end

  def resolve_error_on_records(object_type)
    ActiveRecord::Base.transaction do
      object_type.clear_error!
    rescue StandardError => error
      log_error(error)
      STUCK_JOB_REPORT_SERVICE.append_errors(object_type.class.name, object_type.id, error)
    end
  end

  def clear_rius_errors
    STUCK_JOB_REPORT_SERVICE.append_record_count(rius_with_errors.count, ERROR_TEXT)
    rius_with_errors.each do |riu|
      epe = EndProductEstablishment.find_by(
        id: riu.review_id
      )
      next if epe.established_at.blank?

      resolve_error_on_records(riu)
      STUCK_JOB_REPORT_SERVICE.append_single_record(riu.class.name, riu.id)
    end
    STUCK_JOB_REPORT_SERVICE.append_record_count(rius_with_errors.count, ERROR_TEXT)
  end

  def clear_hlr_errors
    STUCK_JOB_REPORT_SERVICE.append_record_count(hlrs_with_errors.count, ERROR_TEXT)

    hlrs_with_errors.each do |hlr|
      epe = EndProductEstablishment.find_by(
        veteran_file_number: hlr.veteran_file_number
      )
      next if epe.established_at.blank?

      resolve_error_on_records(hlr)
      STUCK_JOB_REPORT_SERVICE.append_single_record(hlr.class.name, hlr.id)
    end
    STUCK_JOB_REPORT_SERVICE.append_record_count(hlrs_with_errors.count, ERROR_TEXT)
  end

  def clear_bge_errors
    STUCK_JOB_REPORT_SERVICE.append_record_count(bges_with_errors.count, ERROR_TEXT)

    bges_with_errors.each do |bge|
      next if bge.end_product_establishment.established_at.blank?

      resolve_error_on_records(bge)
      STUCK_JOB_REPORT_SERVICE.append_single_record(bge.class.name, bge.id)
    end
    STUCK_JOB_REPORT_SERVICE.append_record_count(bges_with_errors.count, ERROR_TEXT)
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
end
