# frozen_string_literal: true

class Api::V3::ClaimantSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower
  set_type :claimant

  attributes :first_name, :middle_name, :last_name, :payee_code
  attribute :relationship_type, &:relationship
end
