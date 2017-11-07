class AddEndProductReferenceIdToRampElections < ActiveRecord::Migration
  def change
    add_column :ramp_elections, :end_product_reference_id, :string
  end
end
