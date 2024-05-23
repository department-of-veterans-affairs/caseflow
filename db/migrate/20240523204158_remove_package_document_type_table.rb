class RemovePackageDocumentTypeTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :package_document_types
  end
end
