# frozen_string_literal: true

require "./lib/helpers/stuck_job_helper.rb"

class ClaimDateDtFixJob < CaseflowJob
  ERROR_TEXT = "ClaimDateDt"
  attr_reader :error_text, :object_type, :logs

  def perform
    return if decision_docs_with_errors.blank?

    StuckJobHelper.s3_record_count(decision_docs_with_errors, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      return unless single_decision_document.processed_at.present? &&
                    single_decision_document.uploaded_to_vbms_at.present?

      StuckJobHelper.single_s3_record_log(single_decision_document)

      ActiveRecord::Base.transaction do
        single_decision_document.clear_error!
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    StuckJobHelper.s3_record_count(decision_docs_with_errors, ERROR_TEXT)

    StuckJobHelper.create_s3_log_report(ERROR_TEXT)

  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
