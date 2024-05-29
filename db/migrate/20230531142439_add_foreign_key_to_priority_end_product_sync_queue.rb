class AddForeignKeyToPriorityEndProductSyncQueue < Caseflow::Migration
  def change
    add_foreign_key :priority_end_product_sync_queue, :end_product_establishments, name: "priority_end_product_sync_queue_end_product_establishment_id_fk", validate: false
  end
end
