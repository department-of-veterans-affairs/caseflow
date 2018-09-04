class ClaimantPowerOfAttorney < BgsPowerOfAttorney
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :claimant_participant_id

  private

  # We need to override the BgsPowerOfAttorney's fetch_bgs_record to use participant id.
  # All of caseflow should probably move to using this since POA is determined by claimant
  # not by Veteran. That said, until we can make that change this is our placeholder.
  def fetch_bgs_record
    bgs.fetch_poas_by_participant_ids([claimant_participant_id])[claimant_participant_id]
  end
end
