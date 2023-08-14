class AddUpdatedAtColumnToPriorityEndProductSyncQueue < Caseflow::Migration
  def change
    add_column :priority_end_product_sync_queue, :updated_at, :datetime, null: false, comment: "Date and Time the record was last updated."
  end
end
