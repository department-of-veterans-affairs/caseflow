class AddDocumentTypePagesToCorrespondenceDocuments < Caseflow::Migration
  def change
    add_column :correspondence_documents, :document_type, :integer, comment: "ID of the doc to lookup VBMS Doc Type"
    add_column :correspondence_documents, :pages, :integer, comment: "Number of pages in the CMP Document"
  end
end
