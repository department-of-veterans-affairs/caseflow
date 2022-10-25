class AlterVbmsDocumentUploadAppealIdColumns < Caseflow::Migration
    def change
      change_column_null :appeal_id, :notified_at, false
      change_column_null :appeal_type, :notified_at, false
    end
  end