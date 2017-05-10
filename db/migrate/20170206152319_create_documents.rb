class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :vbms_document_id, null: false
      t.string :label
    end
    add_index(:documents, :vbms_document_id, unique: true)
  end
end
