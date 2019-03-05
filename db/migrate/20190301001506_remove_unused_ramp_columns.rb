class RemoveUnusedRampColumns < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :ramp_elections, :end_product_reference_id, :string
      remove_column :ramp_elections, :end_product_status, :string
      remove_column :ramp_elections, :end_product_status_last_synced_at, :datetime
      remove_column :ramp_elections, :establishment_attempted_at, :datetime
      remove_column :ramp_elections, :establishment_error, :string
      remove_column :ramp_elections, :establishment_processed_at, :datetime
      remove_column :ramp_elections, :establishment_submitted_at, :datetime

      remove_column :ramp_refilings, :end_product_reference_id, :string
      remove_column :ramp_refilings, :establishment_attempted_at, :datetime
      remove_column :ramp_refilings, :establishment_error, :string
    end
  end
end
