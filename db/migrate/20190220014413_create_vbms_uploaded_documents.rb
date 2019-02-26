class CreateVbmsUploadedDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :vbms_uploaded_documents do |t|
      t.belongs_to :appeal, null: false
      t.datetime :attempted_at
      t.string :document_type, null: false
      t.string :error
      t.datetime :last_submitted_at
      t.datetime :processed_at
      t.datetime :submitted_at
      t.datetime :uploaded_to_vbms_at
      t.timestamps null: false
    end
  end
end
