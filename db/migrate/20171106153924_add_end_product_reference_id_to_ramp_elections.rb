class AddEndProductReferenceIdToRampElections < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_elections, :end_product_reference_id, :string
  end
end
