# frozen_string_literal: true

##
# An attorney can be a claimant when contesting attorney fees. Note that this class represents only
# attorneys with participant IDs in CorpDB, whereas a non-CorpDB attorney is an OtherClaimant.

class AttorneyClaimant < Claimant
  validate { |claimant| ClaimantValidator.new(claimant).validate }

  delegate :name, to: :bgs_attorney

  def advanced_on_docket?(_appeal)
    false
  end

  def advanced_on_docket_based_on_age?
    false
  end

  def advanced_on_docket_motion_granted?(_appeal)
    false
  end

  def relationship
    "Attorney"
  end

  private

  def bgs_attorney
    @bgs_attorney ||= begin
      BgsAttorney.find_by_participant_id(participant_id)
    end
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
