class QualityReviewCaseSelector
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.04

  def self.select_case_for_quality_review?
    rand < QUALITY_REVIEW_SELECTION_PROBABILITY
  end
end
