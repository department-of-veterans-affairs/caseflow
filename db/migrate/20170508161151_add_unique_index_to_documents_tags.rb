class AddUniqueIndexToDocumentsTags < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def change
    add_index(:documents_tags, [:document_id, :tag_id], unique: true, algorithm: :concurrently)
  end
end
