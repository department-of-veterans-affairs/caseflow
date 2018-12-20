class WorkQueue::DecisionReviewTaskSerializer < ActiveModel::Serializer
  def decision_review
    object.appeal
  end

  attribute :claimant do
    # TODO: support multiple?
    decision_review.claimants.first.name
  end

  attribute :appeal do
    {
      id: decision_review.external_id,
      isLegacyAppeal: false,
      issueCount: decision_review.request_issues.count
    }
  end

  attribute :url do
    "TODO"
  end

  attribute :veteran_ssn do
    decision_review.veteran.ssn
  end

  attribute :assigned_on do
    decision_review.assigned_at
  end

  attribute :type do
    decision_review.class.review_title
  end
end
