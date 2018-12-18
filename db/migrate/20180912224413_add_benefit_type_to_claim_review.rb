class AddBenefitTypeToClaimReview < ActiveRecord::Migration[5.1]
  def change
    add_column :higher_level_reviews, :benefit_type, :string
    add_column :supplemental_claims, :benefit_type, :string
  end
end
