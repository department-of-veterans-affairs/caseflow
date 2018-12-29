class DecisionReviewTask < GenericTask
  def label
    appeal_type.constantize.review_title
  end

  def serializer_class
    ::WorkQueue::DecisionReviewTaskSerializer
  end
end
