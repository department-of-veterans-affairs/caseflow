class AddVeteranFileNumberIndexToVbmsUploadedDocuments < Caseflow::Migration
  def change
    add_safe_index :vbms_uploaded_documents, :veteran_file_number, algorithm: :concurrently
  end
end
