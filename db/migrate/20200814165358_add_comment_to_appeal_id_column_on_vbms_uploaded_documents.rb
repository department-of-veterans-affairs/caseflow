class AddCommentToAppealIdColumnOnVbmsUploadedDocuments < Caseflow::Migration
  def change
    change_column_comment :vbms_uploaded_documents, :appeal_id, "Appeal/LegacyAppeal ID; use as FK to appeals/legacy_appeals"
  end
end
