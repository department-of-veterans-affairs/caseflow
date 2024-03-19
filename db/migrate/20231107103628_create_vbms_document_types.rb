class CreateVbmsDocumentTypes < Caseflow::Migration
  def change
    create_table :vbms_document_types do |t|
      t.integer :doc_type_id
      t.timestamps
    end
  end
end
