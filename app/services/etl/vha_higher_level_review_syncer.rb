# frozen_string_literal: true

class ETL::VhaHigherLevelReviewSyncer < ETL::VhaDecisionReviewSyncer
  def origin_class
    ::HigherLevelReview
  end
end
