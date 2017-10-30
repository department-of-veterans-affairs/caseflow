class AddReceivedAtToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :received_at, :date
    add_column :documents, :,, :string
    add_column :documents, :document_type, :string
    add_column :documents, :,, :string
    add_column :documents, :file_number, :string
  end
end
