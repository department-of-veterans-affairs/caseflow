class AddDocumentNameAndDocumentSubjectToVbmsUploadedDocuments < Caseflow::Migration
  def change
    add_column :vbms_uploaded_documents, :document_name, :string
    add_column :vbms_uploaded_documents, :document_subject, :string
  end
end
