# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail"

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        # TODO: ephemeral model that hits BGS and provides a compatible POA interface
        BgsAttorney.find_by(participant_id: poa_participant_id)
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      end
    end
  end
end
