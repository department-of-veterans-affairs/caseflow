# frozen_string_literal: true

class ETL::DecisionReview::SupplementalClaim < ETL::DecisionReview
  class << self
    def unique_attributes
      [
        :benefit_type,
        :decision_review_remanded_id,
        :decision_review_remanded_type
      ]
    end
  end
end
