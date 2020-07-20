# frozen_string_literal: true

##
# An attorney can be a claimant when contesting attorney fees.

class AttorneyClaimant < Claimant
  delegate :name, to: :bgs_attorney

  private

  def find_power_of_attorney
    find_power_of_attorney_by_pid
  end

  def bgs_attorney
    @bgs_attorney ||= begin
      BgsAttorney.find_by_participant_id(participant_id)
    end
  end
end
