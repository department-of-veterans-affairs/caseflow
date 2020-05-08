# frozen_string_literal: true

class ETL::VhaHigherLevelReview < ETL::VhaDecisionReview
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
