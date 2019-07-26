# frozen_string_literal: true

class Api::Preintake::RatingIssue < Api::Preintake::RequestIssue
  def complete_hash
    super.merge(
      rating_issue_reference_id: nil,
      rating_issue_diagnostic_code: nil,
      is_unidentified: true # this is a work around. otherwise decision_text won't be recorded later
    )
  end
end
