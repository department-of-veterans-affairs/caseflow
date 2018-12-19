class DecisionReviewTask < GenericTask
  def label
    appeal_type.constantize.review_title
  end
end
