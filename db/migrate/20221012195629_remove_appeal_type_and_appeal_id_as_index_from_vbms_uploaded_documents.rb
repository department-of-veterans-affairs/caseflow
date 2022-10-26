class RemoveAppealTypeAndAppealIdAsIndexFromVbmsUploadedDocuments < Caseflow::Migration
  def change
    remove_index :vbms_uploaded_documents, column: [:appeal_id, :appeal_type] if index_exists?(:appeal_id, :appeal_type, name: "index_vbms_uploaded_documents_on_appeal_type_and_appeal_id")
  end
end
