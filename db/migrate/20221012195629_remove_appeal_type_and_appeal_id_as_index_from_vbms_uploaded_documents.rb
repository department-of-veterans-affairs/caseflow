class RemoveAppealTypeAndAppealIdAsIndexFromVbmsUploadedDocuments < Caseflow::Migration
  def change
    remove_index :vbms_uploaded_documents, column: [:appeal_id, :appeal_type]
  end
end
