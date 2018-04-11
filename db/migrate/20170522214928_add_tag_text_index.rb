class AddTagTextIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index(:tags, [:text], unique: true, algorithm: :concurrently)
  end
end
