class RemovePackageDocumentTypeTable < Caseflow::Migration
  def change
    drop_table :package_document_types
  end
end
