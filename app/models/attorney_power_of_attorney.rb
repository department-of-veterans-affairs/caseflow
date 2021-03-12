# frozen_string_literal: true

# This is an ephemeral class representing the unrecognized attorney power of attorney of an unrecognized appellant.

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
