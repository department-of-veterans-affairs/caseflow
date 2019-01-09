class DecisionReviewTask < GenericTask
  def label
    appeal_type.constantize.review_title
  end

  def serializer_class
    ::WorkQueue::DecisionReviewTaskSerializer
  end

  def ui_hash
    serializer_class.new(self).as_json
  end
end
