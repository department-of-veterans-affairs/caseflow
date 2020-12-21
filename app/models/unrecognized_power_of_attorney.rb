# frozen_string_literal: true

# This is an ephemeral class representing the unrecognized POA of an unrecognized appellant. The
# UnrecognizedAppellant's unrecognized_power_of_attorney_id column links it directly to the
# UnrecognizedEntityDetail record.

class UnrecognizedPowerOfAttorney
  include ActiveModel::Model
  include HasUnrecognizedEntityDetail

  attr_reader :unrecognized_entity_detail

  def initialize(unrecognized_entity_detail_id)
    @unrecognized_entity_detail = UnrecognizedEntityDetail.find(unrecognized_entity_detail_id)
  end
end
