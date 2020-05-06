# frozen_string_literal: true

class ETL::VhaHigherLevelReviewSyncer < ETL::VhaClaimReviewSyncer
  def origin_class
    ::HigherLevelReview
  end
end
