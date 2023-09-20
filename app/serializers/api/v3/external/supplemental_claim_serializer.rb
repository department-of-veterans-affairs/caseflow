# frozen_string_literal: true

class Api::V3::External::SupplementalClaimSerializer
  include FastJsonapi::ObjectSerializer
  attributes(*SupplementalClaim.column_names)

  attribute :end_product_establishments do |sc|
    sc.end_product_establishments.map do |epe|
      ::Api::V3::External::EndProductEstablishmentSerializer.new(epe)
    end
  end
end
