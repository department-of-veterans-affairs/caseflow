# frozen_string_literal: true

require "./lib/helpers/stuck_job_helper"
class BgsShareErrorFixJob < CaseflowJob
  ERROR_TEXT = "ShareError"

  def share_error
    clear_hlr_errors if hlrs_with_errors.present?
    clear_rius_errors if rius_with_errors.present?
    clear_bge_errors if bges_with_errors.present?
  end

  def resolve_error_on_records(object_type)
    ActiveRecord::Base.transaction do
      object_type.clear_error!
    rescue StandardError => error
      log_error(error)
      # LOG Errors S3
    end
  end

  def clear_rius_errors
    StuckJobHelper.s3_record_count(rius_with_errors, ERROR_TEXT)
    rius_with_errors.each do |riu|
      epe = EndProductEstablishment.find_by(
        id: riu.review_id
      )
      return if epe.established_at.blank?

      resolve_error_on_records(riu)
      StuckJobHelper.single_s3_record_log(riu)
    end
    StuckJobHelper.s3_record_count(rius_with_errors, ERROR_TEXT)
  end

  def clear_hlr_errors
    StuckJobHelper.s3_record_count(hlrs_with_errors, ERROR_TEXT)

    hlrs_with_errors.each do |hlr|
      epe = EndProductEstablishment.find_by(
        veteran_file_number: hlr.veteran_file_number
      )
      return if epe.established_at.blank?

      resolve_error_on_records(hlr)
      StuckJobHelper.single_s3_record_log(hlr)
    end
    StuckJobHelper.s3_record_count(hlrs_with_errors, ERROR_TEXT)
  end

  def  clear_bge_errors
    StuckJobHelper.s3_record_count(bges_with_errors, ERROR_TEXT)

    bges_with_errors.each do |bge|
      return if bge.end_product_establishment.established_at.blank?

      resolve_error_on_records(bge)
      StuckJobHelper.single_s3_record_log(bge)
    end
    StuckJobHelper.s3_record_count(bges_with_errors, ERROR_TEXT)
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
