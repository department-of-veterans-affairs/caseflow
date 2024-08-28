class CreatePackageDocumentTypes < Caseflow::Migration
  def change
    create_table :package_document_types do |t|
      t.string :name
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
