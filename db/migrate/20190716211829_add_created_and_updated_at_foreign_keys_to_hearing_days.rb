class AddCreatedAndUpdatedAtForeignKeysToHearingDays < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_reference :hearing_days, :created_by, foreign_key: {:to_table=>:users}, index: false, comment: "The ID of the user who created the Hearing Day"
    add_index :hearing_days, :created_by_id, algorithm: :concurrently

    add_reference :hearing_days, :updated_by, foreign_key: {:to_table=>:users}, index: false, comment: "The ID of the user who most recently updated the Hearing Day"
    add_index :hearing_days, :updated_by_id, algorithm: :concurrently
  end
end
