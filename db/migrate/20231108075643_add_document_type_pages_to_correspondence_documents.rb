class AddDocumentTypePagesToCorrespondenceDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :correspondence_documents, :document_type, :integer
    add_column :correspondence_documents, :pages, :integer
  end
end
