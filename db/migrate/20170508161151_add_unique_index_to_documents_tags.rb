class AddUniqueIndexToDocumentsTags < ActiveRecord::Migration
  safety_assured
  
  def change
    add_index(:documents_tags, [:document_id, :tag_id], unique: true)
    remove_index :documents_tags, [:document_id]
    remove_index :documents_tags, [:tag_id]
  end
end
