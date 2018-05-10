class AddTypeIndexOnIntakes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :intakes, :type, algorithm: :concurrently
  end
end
