class AddMetadataToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :received_at, :date
    add_column :documents, :type, :string
    add_column :documents, :file_number, :string
  end
end
