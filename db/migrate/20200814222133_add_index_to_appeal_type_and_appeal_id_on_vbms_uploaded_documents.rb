class AddIndexToAppealTypeAndAppealIdOnVbmsUploadedDocuments < Caseflow::Migration
  def change
    add_safe_index :vbms_uploaded_documents, [:appeal_type, :appeal_id], name: :index_vbms_uploaded_documents_on_appeal_type_and_appeal_id
  end
end
