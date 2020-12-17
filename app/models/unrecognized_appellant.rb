# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedEntityDetail

  belongs_to :unrecognized_power_of_attorney

  def power_of_attorney
    if poa_participant_id
      # TODO: ephemeral model that hits BGS and provides a compatible POA interface
      BgsAttorney.find_by(participant_id: poa_participant_id)
    else
      unrecognized_power_of_attorney
    end
  end
end
