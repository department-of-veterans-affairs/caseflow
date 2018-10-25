class AddUserIdToEndProductEstablishments < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :user_id, :integer
  end
end
