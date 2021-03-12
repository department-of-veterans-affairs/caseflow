# frozen_string_literal: true

# This is an ephemeral class representing the unrecognized POA of an unrecognized appellant. The
# UnrecognizedAppellant's unrecognized_power_of_attorney_id column links it directly to the
# UnrecognizedPartyDetail record.

class AttorneyPowerOfAttorney
  include ActiveModel::Model

  delegate :name, :address, to: :bgs_attorney
  attr_accessor :name, :address, :participant_id

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