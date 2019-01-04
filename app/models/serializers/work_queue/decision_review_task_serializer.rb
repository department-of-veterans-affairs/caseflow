class WorkQueue::DecisionReviewTaskSerializer < ActiveModel::Serializer
  def task
    object
  end

  def decision_review
    task.appeal
  end

  attribute :claimant do
    if decision_review.claimants.any?
      # TODO: support multiple?
      decision_review.claimants.first.try(:name)
    else
      decision_review.veteran_full_name
    end
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

  attribute :veteran_participant_id do
    decision_review.veteran.participant_id
  end

  attribute :assigned_on do
    task.assigned_at
  end

  attribute :completed_at do
    task.completed_at
  end

  attribute :started_at do
    task.started_at
  end

  attribute :type do
    decision_review.class.review_title
  end
end
