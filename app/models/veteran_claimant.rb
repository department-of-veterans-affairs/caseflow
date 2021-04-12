# frozen_string_literal: true

class VeteranClaimant < BgsRelatedClaimant
  bgs_attr_accessor :relationship

  private

  def find_power_of_attorney
    BgsPowerOfAttorney.find_or_fetch_by(
      participant_id: participant_id,
      veteran_file_number: decision_review.veteran_file_number
    )
  end
end
