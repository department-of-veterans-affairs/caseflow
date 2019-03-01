class RemoveUnusedRampColumns < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :ramp_elections, :end_product_reference_id
      remove_column :ramp_elections, :end_product_status
      remove_column :ramp_elections, :end_product_status_last_synced_at
      remove_column :ramp_elections, :establishment_attempted_at
      remove_column :ramp_elections, :establishment_error
      remove_column :ramp_elections, :establishment_processed_at
      remove_column :ramp_elections, :establishment_submitted_at

      remove_column :ramp_refilings, :end_product_reference_id
      remove_column :ramp_refilings, :establishment_attempted_at
      remove_column :ramp_refilings, :establishment_error
    end
  end
end
