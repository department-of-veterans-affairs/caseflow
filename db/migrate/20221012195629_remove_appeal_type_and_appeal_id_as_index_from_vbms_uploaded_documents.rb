class RemoveAppealTypeAndAppealIdAsIndexFromVbmsUploadedDocuments < ActiveRecord::Migration[5.2]
  def change
    remove_index :vbms_uploaded_documents, :appeal_id
    remove_index :vbms_uploaded_documents, name: "index_vbms_uploaded_documents_on_appeal_type_and_appeal_id"
  end
end
