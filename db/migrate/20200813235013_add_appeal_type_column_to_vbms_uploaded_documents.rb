class AddAppealTypeColumnToVbmsUploadedDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :vbms_uploaded_documents, :appeal_type, :string, comment: "'Appeal' or 'LegacyAppeal'"
  end
end
