class AddCreatedByIdAndUpdatedByIdToHearings < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_reference(
      :hearings,
      :created_by,
      foreign_key: { to_table: :users },
      comment: "The ID of the user who created the Hearing",
      index: false
    )
    add_reference(
      :hearings,
      :updated_by,
      foreign_key: { to_table: :users },
      comment: "The ID of the user who most recently updated the Hearing",
      index: false
    )

    add_index :hearings, :created_by_id, algorithm: :concurrently
    add_index :hearings, :updated_by_id, algorithm: :concurrently
  end
end
