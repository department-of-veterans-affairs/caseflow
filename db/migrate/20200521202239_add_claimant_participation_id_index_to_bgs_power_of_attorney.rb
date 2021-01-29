class AddClaimantParticipationIdIndexToBgsPowerOfAttorney < Caseflow::Migration
  def change
    add_safe_index :bgs_power_of_attorneys, :claimant_participant_id
  end
end
