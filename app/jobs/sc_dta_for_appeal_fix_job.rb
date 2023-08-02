# frozen_string_literal: true

require "./lib/helpers/stuck_job_helper.rb"

class ScDtaForAppealFixJob < CaseflowJob
  ERRORTEXT = "Can't create a SC DTA for appeal"

  def records_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERRORTEXT}%")
  end

  def sc_dta_for_appeal_fix
    return if records_with_errors.blank?

    # count of records with errors before fix
    StuckJobHelper.s3_record_count(records_with_errors, ERRORTEXT)

    records_with_errors.each do |decision_doc|
      claimant = decision_doc.appeal.claimant

      return unless claimant.payee_code.nil?

      if claimant.type == "VeteranClaimant"
        claimant.update!(payee_code: "00")
      elsif claimant.type == "DependentClaimant"
        claimant.update!(payee_code: "10")
      end
      StuckJobHelper.single_s3_record_log(decision_doc)
      clear_error_on_record(decision_doc)
    end

    # record count with errors after fix
    StuckJobHelper.s3_record_count(records_with_errors, ERRORTEXT)
    StuckJobHelper.create_s3_log_report(ERRORTEXT)
  end

  def clear_error_on_record(decision_doc)
    ActiveRecord::Base.transaction do
      decision_doc.clear_error!
    rescue StandardError
      raise ActiveRecord::Rollback
    end
  end
end
