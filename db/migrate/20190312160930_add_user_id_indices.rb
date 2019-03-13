class AddUserIdIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    [
     "claims_folder_searches",
     "dispatch_tasks",
     "end_product_establishments",
     "legacy_hearings"
    ].each do |tbl|
       add_index tbl, :user_id, algorithm: :concurrently
    end
  end
end
