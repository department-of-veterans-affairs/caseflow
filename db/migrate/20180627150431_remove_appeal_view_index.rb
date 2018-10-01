class RemoveAppealViewIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  safety_assured

  def up
    remove_index :appeal_views, name: "index_appeal_views_on_appeal_id_and_user_id", algorithm: :concurrently
  end

  def down
    add_index :appeal_views, [:appeal_id, :user_id], algorithm: :concurrently, unique: true
  end
end
