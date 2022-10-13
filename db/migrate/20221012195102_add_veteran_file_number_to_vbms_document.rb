class AddVeteranFileNumberToVbmsDocument < ActiveRecord::Migration[5.2]
  def change
    add_column :vbms_uploaded_documents, :veteran_file_number, :string, null: false
  end
end
