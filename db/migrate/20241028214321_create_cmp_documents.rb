class CreateCmpDocuments < ActiveRecord::Migration[6.1]
  def change
    create_table :cmp_documents do |t|
      t.string :packet_uuid, null: false
      t.string :cmp_document_id, null: false
      t.string :cmp_document_uuid, null: false
      t.integer :vbms_doctype_id, null: false
      t.string :doctype_name, null: true
      t.datetime :date_of_receipt, null: false
      t.references :cmp_mail_packet, foreign_key: true, null: true

      t.timestamps
    end
  end
end
