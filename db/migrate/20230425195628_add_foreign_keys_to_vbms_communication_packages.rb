class AddForeignKeysToVbmsCommunicationPackages < Caseflow::Migration
  def change
    safety_assured { add_reference(:vbms_communication_packages, :vbms_uploaded_document, foreign_key: { to_table: :vbms_uploaded_documents}, null: false) }
    safety_assured { add_reference(:vbms_communication_packages, :created_by, foreign_key: { to_table: :users}, null: false) }
    safety_assured { add_reference(:vbms_communication_packages, :updated_by, foreign_key: { to_table: :users}) }
  end
end
