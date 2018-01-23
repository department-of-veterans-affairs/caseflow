class AddDocumentsIndexToFileNumber < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :documents, :file_number, algorithm: :concurrently
  end
end
