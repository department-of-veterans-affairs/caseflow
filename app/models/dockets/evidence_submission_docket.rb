# frozen_string_literal: true

class EvidenceSubmissionDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.evidence_submission
  end

  def docket_time_goal
    @docket_time_goal ||= CaseDistributionLever.ama_evidence_submission_docket_time_goals
  end

  def start_distribution_prior_to_goal
    @start_distribution_prior_to_goal ||= CaseDistributionLever.ama_evidence_submission_start_distribution_prior_to_goals
  end
end
