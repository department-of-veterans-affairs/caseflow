# frozen_string_literal: true

class NoAvailableModifiersFixJob < CaseflowJob
  ERROR_TEXT = "NoAvailableModifiers"

  attr_reader :decision_review_job

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @decision_review_job = DecisionReviewProcessJob.new
    super
  end

  def perform
    @stuck_job_report_service.append_record_count(supp_claims_with_errors_count, ERROR_TEXT)

    veterans_with_errors.each do |vet_fn|
      active_count = current_active_eps_count(vet_fn) || 0
      available_space = 10 - active_count
      next if available_space <= 0

      supp_claims = supp_claims_on_veteran(vet_fn)
      break if supp_claims.empty?

      process_supplemental_claims(supp_claims, available_space)
    end
    @stuck_job_report_service.append_record_count(supp_claims_with_errors_count, ERROR_TEXT)
    @stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def process_supplemental_claims(supp_claims, available_space)
    supp_claims.each do |sc|
      break if available_space <= 0

      @stuck_job_report_service.append_single_record(sc.class.name, sc.id)
      ActiveRecord::Base.transaction do
        decision_review_job.perform(sc)
      rescue StandardError => error
        log_error(error)
        @stuck_job_report_service.append_errors(sc.class.name, sc.id, error)
      end
      available_space -= 1
    end
  end

  def end_products_on_veteran(file_number)
    EndProductEstablishment.where(veteran_file_number: file_number)
  end

  def supp_claims_on_veteran(file_number)
    SupplementalClaim.where("establishment_error ILIKE ?", "%#{ERROR_TEXT}%").where(veteran_file_number: file_number)
  end

  def current_active_eps_count(file_number)
    synced_statuses = EndProductEstablishment.where(veteran_file_number: file_number).pluck(:synced_status).compact
    synced_statuses.count { |status| status != "CAN" && status != "CLR" }
  end

  def veterans_with_errors
    SupplementalClaim.where("establishment_error ILIKE ?",
                            "%#{ERROR_TEXT}%").pluck(:veteran_file_number).uniq
  end

  def supp_claims_with_errors_count
    SupplementalClaim.where("establishment_error ILIKE ?", "%#{ERROR_TEXT}%").count
  end
end
