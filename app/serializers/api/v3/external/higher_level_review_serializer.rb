# frozen_string_literal: true

class Api::V3::External::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_type :higher_level_review
  attributes *HigherLevelReview.column_names

  attribute :end_product_establishments do |hlr|
    hlr.end_product_establishments.map do |epe|
      ::Api::V3::External::EndProductEstablishmentSerializer.new(epe)
    end
  end
end
