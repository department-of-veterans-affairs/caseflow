# frozen_string_literal: true

require_relative "stuck_job_queries.rb"
module StuckJobsErrorCounter
  extend StuckJobQueries

  ERROR_COUNT_MAP = {
    ClaimDateDtFixJob => lambda {
      Rails.logger.info "Executing lambda for ClaimDateDtFixJob"
      count = decision_documents_with_errors(ClaimDateDtFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for ClaimDateDtFixJob executed. Result: #{count}"
      count
    },
    BgsShareErrorFixJob => lambda {
      Rails.logger.info "Executing lambda for BgsShareErrorFixJob"
      count = higher_level_review_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count +
              request_issues_updates_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count +
              board_grant_effectuations_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for BgsShareErrorFixJob executed. Result: #{count}"
      count
    },
    ClaimNotEstablishedFixJob => lambda {
      Rails.logger.info "Executing lambda for ClaimNotEstablishedFixJob"
      count = decision_documents_with_errors(ClaimNotEstablishedFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for ClaimNotEstablishedFixJob executed. Result: #{count}"
      count
    },
    NoAvailableModifiersFixJob => lambda {
      Rails.logger.info "Executing lambda for NoAvailableModifiersFixJob"
      count = supplemental_claims_with_errors(NoAvailableModifiersFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for NoAvailableModifiersFixJob executed. Result: #{count}"
      count
    },
    PageRequestedByUserFixJob => lambda {
      Rails.logger.info "Executing lambda for PageRequestedByUserFixJob"
      count = board_grant_effectuations_with_errors(PageRequestedByUserFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for PageRequestedByUserFixJob executed. Result: #{count}"
      count
    },
    DtaScCreationFailedFixJob => lambda {
      Rails.logger.info "Executing lambda for DtaScCreationFailedFixJob"
      count = higher_level_review_with_errors(DtaScCreationFailedFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for DtaScCreationFailedFixJob executed. Result: #{count}"
      count
    },
    ScDtaForAppealFixJob => lambda {
      Rails.logger.info "Executing lambda for ScDtaForAppealFixJob"
      count = decision_documents_with_errors(ScDtaForAppealFixJob::ERROR_TEXT).count
      Rails.logger.info "Lambda for ScDtaForAppealFixJob executed. Result: #{count}"
      count
    }
    # ... add more lambdas for other job classes
  }.freeze

  def self.errors_count_for_job(job_class)
    ERROR_COUNT_MAP.fetch(job_class, -> { 0 }).call
  end
end
