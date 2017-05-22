class AddTagTextIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index(:tags, [:text], unique: true, algorithm: :concurrently)
  end
end
