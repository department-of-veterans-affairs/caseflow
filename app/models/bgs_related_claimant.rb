# frozen_string_literal: true

class BgsRelatedClaimant < Claimant
  include AssociatedBgsRecord

  validate { |claimant| ClaimantValidator.new(claimant).validate }

  def fetch_bgs_record
    general_info = bgs.fetch_claimant_info_by_participant_id(participant_id)
    name_info = bgs.fetch_person_info(participant_id)

    general_info.merge(name_info)
  end

  def bgs_payee_code
    return unless bgs_record

    bgs_record[:payee_code]
  end

  def bgs_record
    @bgs_record ||= try_and_retry_bgs_record
  end

  def find_power_of_attorney
    BgsPowerOfAttorney.find_or_fetch_by(participant_id: participant_id)
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
