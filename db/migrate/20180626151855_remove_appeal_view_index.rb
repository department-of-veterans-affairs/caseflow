class RemoveAppealViewIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  safety_assured

  def change
    remove_index :appeal_views, name: "index_appeal_views_on_appeal_id_and_user_id", algorithm: :concurrently
  end
end
