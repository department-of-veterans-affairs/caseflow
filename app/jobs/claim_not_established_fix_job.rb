# frozen_string_literal: true

require "./lib/helpers/stuck_job_helper.rb"

class ClaimNotEstablishedFixJob < CaseflowJob
  ERROR_TEXT = "Claim not established."
  EPECODES = %w[030 040 930 682].freeze

  attr_reader :error_text, :object_type, :logs

  def perform
    return if decision_docs_with_errors.blank?

    StuckJobHelper.s3_record_count(decision_docs_with_errors, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      file_number = single_decision_document.veteran.file_number
      epe = EndProductEstablishment.find_by(veteran_file_number: file_number)
      return unless validate_epe(epe)

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

  def validate_epe(epe)
    epe_code = epe&.code&.slice(0, 3)
    EPECODES.include?(epe_code) && epe&.established_at.present?
  end
end
