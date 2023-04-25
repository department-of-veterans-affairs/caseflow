class CreateVbmsCommunicationPackages < Caseflow::Migration
  def change
    create_table :vbms_communication_packages do |t|
      t.string :file_number
      t.bigint :document_referenced, default: [], array: true
      t.string :status
      t.string :comm_package_name, null: false
      t.timestamps
    end
  end
end
