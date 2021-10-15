class AddVeteranIdToIntakes < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_reference :intakes, :veteran, foreign_key: true, comment: "The ID of the veteran record associated with this intake", index: false
    add_safe_index :intakes, :veteran_id, algorithm: :concurrently
  end
end
