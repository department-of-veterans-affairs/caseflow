class AddUniqueIndexToHearingTaskAssociation < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :hearing_task_associations,
        [:hearing_id, :hearing_type, :hearing_task_id],
        name: "index_hearing_task_associations_on_hearing_id_type_and_task_id",
        unique: true,
        algorithm: :concurrently,
        comment: "Ensure a unique 1:1 relationship between hearings and hearing tasks."
  end
end
