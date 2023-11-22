# frozen_string_literal: true

module StuckJobsErrorCounter
  include StuckJobQueries

  # Define new error queries here when the error exists on multiple types of
  # records for a job.
  BGS_SHARE_ERROR_QUERY = [
    HigherLevelReview.where("establishment_error ILIKE?", "%ShareError%"),
    RequestIssuesUpdate.where("error ILIKE?", "%ShareError%"),
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%ShareError%")
  ].freeze

  def self.errors_count_for_job(job_class)
    case job_class
    when ClaimDateDtFixJob
      binding.pry
      decision_documents_with_errors(ClaimDateDtFixJob::ERROR_TEXT)
      DecisionDocument.where("error ILIKE ?", "%ClaimDateDt%").count
    when BgsShareErrorFixJob
      total_errors_count(BGS_SHARE_ERROR_QUERY)
    when ClaimNotEstablishedFixJob
      DecisionDocument.where("error ILIKE ?", "%Claim not established%").count
    when NoAvailableModifiersFixJob
      SupplementalClaim.where("establishment_error ILIKE ?", "%NoAvailableModifiers%").count
    when PageRequestedByUserFixJob
      BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%Page requested by the user is unavailable%").count
    when DtaScCreationFailedFixJob
      HigherLevelReview.where("establishment_error ILIKE ?", "%DTA SC Creation Failed%").count
    when ScDtaForAppealFixJob
      DecisionDocument.where("error ILIKE ?", "%Can't create a SC DTA for appeal%").count
    else
      0
      # Add additionl error count queries when new stuck jobs are added
    end
  end

  def self.total_errors_count(queries)
    return 0 if queries.nil? || queries.empty?

    total_count = 0

    queries.each do |query|
      total_count += query.count
    end

    total_count
  end
end
