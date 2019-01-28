class WorkQueue::BoardGrantEffectuationTaskSerializer < WorkQueue::DecisionReviewTaskSerializer
  attribute :type do
    "Board Grant"
  end
end
