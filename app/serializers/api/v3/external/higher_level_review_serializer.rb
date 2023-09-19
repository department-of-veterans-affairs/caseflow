# frozen_string_literal: true

class Api::V3::External::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  attributes
  has_many :end_product_establishments, serializer: ::Api::V3::External::EndProductEstablishmentSerializer
end
