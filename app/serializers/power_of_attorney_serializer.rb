# frozen_string_literal: true

class PowerOfAttorneySerializer
  include FastJsonapi::ObjectSerializer

  attribute :representative_type
  attribute :representative_name
  attribute :representative_address
  attribute :representative_email_address
  attribute :representative_tz
  attribute :representative_id
  attribute :poa_last_synced_at
end
