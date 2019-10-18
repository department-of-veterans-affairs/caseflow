class Api::V3::ClaimantSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attributes :first_name, :middle_name, :last_name, :payee_code, :relationship_type
end