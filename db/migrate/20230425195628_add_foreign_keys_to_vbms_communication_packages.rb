class AddForeignKeysToVbmsCommunicationPackages < Caseflow::Migration
  def change
    add_reference :vbms_communication_packages, :vbms_uploaded_documents, foreign_key: true, null: false
    add_reference :vbms_communication_packages, :created_by, foreign_key: { to_table: :users}
    add_reference :vbms_communication_packages, :updated_by, foreign_key: { to_table: :users}
  end
end
