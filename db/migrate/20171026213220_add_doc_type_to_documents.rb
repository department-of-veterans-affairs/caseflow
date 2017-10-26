class AddDocTypeToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :document_type, :string
  end
end
