class AddFileNumberToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :file_number, :string
  end
end
