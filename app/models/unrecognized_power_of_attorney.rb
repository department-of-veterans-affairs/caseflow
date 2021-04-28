# frozen_string_literal: true

# This is an ephemeral class representing the unrecognized POA of an unrecognized appellant. The
# UnrecognizedAppellant's unrecognized_power_of_attorney_id column links it directly to the
# UnrecognizedPartyDetail record.

class UnrecognizedPowerOfAttorney
  include ActiveModel::Model
  include HasUnrecognizedPartyDetail

  attr_reader :unrecognized_party_detail

  alias representative_name name
  alias representative_address address
  alias representative_email_address email_address

  def initialize(unrecognized_party_detail)
    @unrecognized_party_detail = unrecognized_party_detail
  end

  def representative_type
    "Unrecognized representative"
  end

  def participant_id
    nil
  end

  def poa_last_synced_at
    unrecognized_party_detail.updated_at
  end
end
