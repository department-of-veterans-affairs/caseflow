class AddVeteranFileNumberIndexToVbmsUploadedDocuments < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :vbms_uploaded_documents, :veteran_file_number, algorithm: :concurrently
  end
end
