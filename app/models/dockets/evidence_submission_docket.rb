# frozen_string_literal: true

class EvidenceSubmissionDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.evidence_submission
  end
end
