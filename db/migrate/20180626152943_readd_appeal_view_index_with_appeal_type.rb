class ReaddAppealViewIndexWithAppealType < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  safety_assured

  def change
    add_index :appeal_views, [:appeal_type, :appeal_id, :user_id], algorithm: :concurrently, unique: true
  end
end
