class AddInboxMessageDetail < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :messages, :detail_type, :string, comment: "Model name of the related object"
    add_column :messages, :detail_id, :integer, comment: "ID of the related object"

    add_index :messages, [:detail_type, :detail_id], algorithm: :concurrently
  end
end
