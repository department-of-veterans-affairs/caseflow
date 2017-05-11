class AddUniqueIndexToDocumentsTags < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    add_index(:documents_tags, [:document_id, :tag_id], unique: true, algorithm: :concurrently)
  end
end
