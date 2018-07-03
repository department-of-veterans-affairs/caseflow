class DropIntakeUniquenessIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  safety_assured

  def change
    remove_index :intakes, name: 'unique_index_to_avoid_duplicate_intakes', algorithm: :concurrently
    remove_index :intakes, name: 'unique_index_to_avoid_multiple_intakes', algorithm: :concurrently
  end
end
