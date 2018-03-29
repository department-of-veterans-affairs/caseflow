class AddEndProductStatusToRampElection < ActiveRecord::Migration
  def change
    add_column :ramp_elections, :end_product_status, :string
    add_column :ramp_elections, :end_product_status_last_synced_at, :datetime
  end
end
