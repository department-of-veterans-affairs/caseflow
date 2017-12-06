class AddTypeIndexOnIntakes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :intakes, :type, algorithm: :concurrently
  end
end
