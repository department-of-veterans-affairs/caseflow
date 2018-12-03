class AddClaimantTypeToReviewRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :higher_level_reviews, :veteran_is_not_claimant, :boolean
    add_column :supplemental_claims, :veteran_is_not_claimant, :boolean
    add_column :appeals, :veteran_is_not_claimant, :boolean
  end
end
