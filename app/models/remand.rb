# frozen_string_literal: true

class Remand < SupplementalClaim
  has_many :request_issues, -> { where(request_issues: { decision_review_type: "Remand" }) },
           class_name: "RequestIssue",
           foreign_key: "decision_review_id"
end
