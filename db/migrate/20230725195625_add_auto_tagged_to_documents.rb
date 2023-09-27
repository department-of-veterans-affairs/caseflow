class AddAutoTaggedToDocuments < Caseflow::Migration
  def change
    add_column :documents, :auto_tagged, :boolean, null: true, default: false
  end
end
