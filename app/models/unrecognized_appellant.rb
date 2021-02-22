# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail, dependent: :destroy
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail", dependent: :destroy

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        # Return an ephemeral model that hits BGS with poa_participant_id and provides a
        # compatible POA interface
        fail NotImplementedError
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      end
    end
  end
end
