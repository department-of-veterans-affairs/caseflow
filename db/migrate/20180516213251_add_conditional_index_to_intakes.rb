class AddConditionalIndexToIntakes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :intakes, [:type, :veteran_file_number], algorithm: :concurrently, name: 'unique_index_to_avoid_duplicate_intakes', where: "completion_status is NULL", unique: true
  end
end
