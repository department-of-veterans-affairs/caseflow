# frozen_string_literal: true

class Api::V3::External::SupplementalClaimSerializer
  include FastJsonapi::ObjectSerializer
  set_type :supplemental_claim
  attributes *SupplementalClaim.column_names
  has_many :end_product_establishments, serializer: ::Api::V3::External::EndProductEstablishmentSerializer
end
