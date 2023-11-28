# frozen_string_literal: true

require_relative "stuck_job_queries.rb"

module StuckJobsErrorCounter
  include StuckJobQueries

  def self.errors_count_for_job(job_class)
    case job_class
    when ClaimDateDtFixJob
      decision_documents_with_errors(ClaimDateDtFixJob::ERROR_TEXT).count
    when BgsShareErrorFixJob
      higher_level_review_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count +
        request_issues_updates_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count +
        board_grant_effectuations_with_errors(BgsShareErrorFixJob::ERROR_TEXT).count
    when ClaimNotEstablishedFixJob
      decision_documents_with_errors(ClaimNotEstablishedFixJob::ERROR_TEXT).count
    when NoAvailableModifiersFixJob
      supplemental_claims_with_errors(NoAvailableModifiersFixJob::ERROR_TEXT).count
    when PageRequestedByUserFixJob
      board_grant_effectuations_with_errors(PageRequestedByUserFixJob::ERROR_TEXT).count
    when DtaScCreationFailedFixJob
      hlrs_with_errors(DtaScCreationFailedFixJob::ERROR_TEXT).count
    when ScDtaForAppealFixJob
      decision_documents_with_errors(ScDtaForAppealFixJob::ERROR_TEXT).count

      # Add additional Stuck Jobs here for reporting during automated execution
    else
      0
    end
  end
end
