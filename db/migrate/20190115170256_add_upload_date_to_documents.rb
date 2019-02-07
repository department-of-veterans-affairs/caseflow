class AddUploadDateToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :upload_date, :date
  end
end
