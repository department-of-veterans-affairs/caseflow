class AddPreviousDocumentVersionToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :previous_document_version_id, :integer
  end
end
