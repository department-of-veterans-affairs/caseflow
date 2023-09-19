# frozen_string_literal: true

class Api::V3::External::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_type :higher_level_review
  attributes *HigherLevelReview.column_names
  has_many :end_product_establishments, serializer: ::Api::V3::External::EndProductEstablishmentSerializer
end
