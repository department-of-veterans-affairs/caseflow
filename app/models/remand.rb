# frozen_string_literal: true

class Remand < SupplementalClaim
  has_many :request_issues, lambda {
                              where("supplemental_claims.type = ?", "Remand")
                                .where(request_issues: { decision_review_type: "SupplementalClaim" })
                            },
           class_name: "RequestIssue",
           foreign_key: "decision_review_id"
end
