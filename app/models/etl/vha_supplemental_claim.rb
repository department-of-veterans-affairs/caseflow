# frozen_string_literal: true

class ETL::VhaSupplementalClaim < ETL::VhaDecisionReview
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
