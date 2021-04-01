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
    "Attorney"
  end

  def bgs_attorney
    @bgs_attorney ||= begin
      BgsAttorney.find_by_participant_id(participant_id)
    end
  end
end
