class AddHealthcareProviderClaimantToColumnComments < ActiveRecord::Migration[5.2]
  def change
    change_column_comment :claimants, :type, "The class name for the single table inheritance type of Claimant, for example VeteranClaimant, DependentClaimant, AttorneyClaimant, OtherClaimant, or HealthcareProviderClaimant."
    change_column_comment :unrecognized_appellants, :claimant_id, "The OtherClaimant or HealthcareProviderClaimant record associating this appellant to a DecisionReview."
  end
end
