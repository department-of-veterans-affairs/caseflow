class AddVeteranFileNumberToVbmsDocument < Caseflow::Migration
  def change
    add_column :vbms_uploaded_documents, :veteran_file_number, :string
  end
end
