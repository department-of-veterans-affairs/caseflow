class RemoveAppealIdAndTypeColumnFromVbmsUploadedDocuments < Caseflow::Migration
  def change
    safety_assured { remove_column :vbms_uploaded_documents, :appeal_id, :string }
    safety_assured { remove_column :vbms_uploaded_documents, :appeal_type, :string }
    end
end
