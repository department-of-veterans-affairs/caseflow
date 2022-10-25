class AlterVbmsDocumentUploadAppealIdColumns < Caseflow::Migration
    def change
      change_column_null :vbms_uploaded_documents, :appeal_id, false
      change_column_null :vbms_uploaded_documents, :appeal_type, false
    end
  end