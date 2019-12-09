class AddAppealStatusSort < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :appeals, :decision_status_sort_key, :integer, null: false
    add_index :appeals, :decision_status_sort_key, algorithm: :concurrently
  end
end
