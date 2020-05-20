# frozen_string_literal: true

class ETL::DecisionReview::HigherLevelReview < ETL::DecisionReview
  class << self
    def unique_attributes
      [
        :benefit_type,
        :informal_conference,
        :same_office
      ]
    end
  end
end
