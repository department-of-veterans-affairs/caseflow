# frozen_string_literal: true

require "./lib/helpers/stuck_job_helper"
class DtaScCreationFailedFixJob < CaseflowJob
  ERROR_TEXT = "DTA SC Creation Failed"
  attr_reader :error_text, :object_type, :logs

  def perform
    return if hlrs_with_errors.blank?

    StuckJobHelper.s3_record_count(hlrs_with_errors, ERROR_TEXT)

    hlrs_with_errors.each do |hlr|
      return unless SupplementalClaim.find_by(
        decision_review_remanded_id: hlr.id,
        decision_review_remanded_type: "HigherLevelReview"
      )

      StuckJobHelper.single_s3_record_log(hlr)

      ActiveRecord::Base.transaction do
        hlr.clear_error!
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    StuckJobHelper.s3_record_count(hlrs_with_errors, ERROR_TEXT)
    StuckJobHelper.create_s3_log_report(ERROR_TEXT)
  end

  def hlrs_with_errors
    HigherLevelReview.where("establishment_error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
