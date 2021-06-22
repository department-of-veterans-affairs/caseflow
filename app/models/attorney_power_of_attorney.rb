# frozen_string_literal: true

# This is an ephemeral class representing an unrecognized appellant's power of attorney when it is a listed
# attorney returned from the Corporate DB.

class AttorneyPowerOfAttorney
  include ActiveModel::Model

  delegate :name, :address, to: :bgs_attorney
  attr_accessor :participant_id

  alias representative_name name
  alias representative_address address

  def initialize(participant_id)
    @participant_id = participant_id
  end

  def representative_type
    # See the BgsAttorney factory for record_type values as seen in the wild.
    # We remove "POA" prefix to be consistent with BgsPowerOfAttorney#representative_type
    bgs_attorney.record_type.delete_prefix("POA ")
  end

  def representative_email_address
    nil
  end

  def poa_last_synced_at
    nil
  end

  def stale_attributes?
    nil
  end

  def bgs_attorney
    @bgs_attorney ||= begin
      BgsAttorney.find_by_participant_id(participant_id)
    end
  end
end
