# frozen_string_literal: true

# This is an ephemeral class representing an not listed appellant's power of attorney when there is no listed
# attorney returned from the Corporate DB by that name.

class NotListedPowerOfAttorney < CaseflowRecord
  include ActiveModel::Model

  has_one :unrecognized_appellant

  serialized_methods = {
    representative_type: "not_listed",
    representative_name: nil,
    representative_address: nil,
    representative_email_address: nil,
    poa_last_synced_at: nil
  }.freeze

  serialized_methods.each do |method_name, value|
    define_method(method_name) { value }
  end
end
