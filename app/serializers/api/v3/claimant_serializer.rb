# frozen_string_literal: true

class Api::V3::ClaimantSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = "Claimant"

  attributes :first_name, :middle_name, :last_name, :payee_code
  attribute :relationship_type, &:relationship
end
