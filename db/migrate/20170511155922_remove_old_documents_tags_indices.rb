class RemoveOldDocumentsTagsIndices < ActiveRecord::Migration[5.1]
  def change
    remove_index :documents_tags, [:document_id]
    remove_index :documents_tags, [:tag_id]
  end
end
