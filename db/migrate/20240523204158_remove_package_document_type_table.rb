class RemovePackageDocumentTypeTable < Caseflow::Migration

  def up
    drop_table :package_document_types
  end

  def down
    create_table :package_document_types do |t|
      t.string :name
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
