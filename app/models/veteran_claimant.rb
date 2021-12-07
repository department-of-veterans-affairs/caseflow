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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: claimants
#
#  id                   :bigint           not null, primary key
#  decision_review_type :string           not null, indexed => [decision_review_id]
#  notes                :text
#  payee_code           :string
#  type                 :string           default("Claimant")
#  created_at           :datetime
#  updated_at           :datetime         indexed
#  decision_review_id   :bigint           not null, indexed => [decision_review_type]
#  participant_id       :string           not null, indexed
#
