class AlterVbmsDocumentUploadAppealIdColumns < Caseflow::Migration
    def change
      change_column_null :vbms_uploaded_documents, :appeal_id, true
      change_column_null :vbms_uploaded_documents, :appeal_type, true
    end
  end