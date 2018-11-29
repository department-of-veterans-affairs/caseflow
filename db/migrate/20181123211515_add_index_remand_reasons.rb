class AddIndexRemandReasons < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def change
    add_index :remand_reasons, :decision_issue_id, algorithm: :concurrently
  end
end
