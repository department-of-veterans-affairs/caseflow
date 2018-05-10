class AddPreviousDocumentVersionToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :previous_document_version_id, :integer
  end
end
