class RemoveAppealIdAndTypeColumnFromVbmsUploadedDocuments < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :vbms_uploaded_documents, :appeal_id }
    safety_assured { remove_column :vbms_uploaded_documents, :appeal_type }
    end
end
