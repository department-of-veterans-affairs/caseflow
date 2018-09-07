class AddCommittedAtToEndProductEstablishments < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :committed_at, :datetime
  end
end
