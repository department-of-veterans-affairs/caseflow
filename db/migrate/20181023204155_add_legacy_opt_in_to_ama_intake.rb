class AddLegacyOptInToAmaIntake < ActiveRecord::Migration[5.1]
  def change
    add_column :higher_level_reviews, :legacy_opt_in_approved, :boolean
    add_column :supplemental_claims, :legacy_opt_in_approved, :boolean
    add_column :appeals, :legacy_opt_in_approved, :boolean
  end
end
