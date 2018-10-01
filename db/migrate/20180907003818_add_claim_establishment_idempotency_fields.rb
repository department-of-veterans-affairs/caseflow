class AddClaimEstablishmentIdempotencyFields < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    add_column :request_issues, :removed_at, :datetime
    add_column :request_issues, :rating_issue_associated_at, :datetime
    add_column :ramp_elections, :establishment_submitted_at, :datetime
    add_column :ramp_elections, :establishment_processed_at, :datetime
    add_column :ramp_refilings, :establishment_submitted_at, :datetime
    add_column :ramp_refilings, :establishment_processed_at, :datetime
    add_column :higher_level_reviews, :establishment_submitted_at, :datetime
    add_column :higher_level_reviews, :establishment_processed_at, :datetime
    add_column :supplemental_claims, :establishment_submitted_at, :datetime
    add_column :supplemental_claims, :establishment_processed_at, :datetime
    remove_column :higher_level_reviews, :established_at
    remove_column :higher_level_reviews, :end_product_reference_id
    remove_column :higher_level_reviews, :end_product_status
    remove_column :higher_level_reviews, :end_product_status_last_synced_at
    remove_column :supplemental_claims, :established_at
    remove_column :supplemental_claims, :end_product_reference_id
    remove_column :supplemental_claims, :end_product_status
    remove_column :supplemental_claims, :end_product_status_last_synced_at

  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
