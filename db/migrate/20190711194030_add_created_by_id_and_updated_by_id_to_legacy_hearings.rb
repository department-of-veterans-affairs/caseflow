class AddCreatedByIdAndUpdatedByIdToLegacyHearings < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_reference(
      :legacy_hearings,
      :created_by,
      foreign_key: { to_table: :users },
      comment: "The ID of the user who created the Legacy Hearing",
      index: false
    )
    add_reference(
      :legacy_hearings,
      :updated_by,
      foreign_key: { to_table: :users },
      comment: "The ID of the user who most recently updated the Legacy Hearing",
      index: false
    )

    add_index :legacy_hearings, :created_by_id, algorithm: :concurrently
    add_index :legacy_hearings, :updated_by_id, algorithm: :concurrently
  end
end
