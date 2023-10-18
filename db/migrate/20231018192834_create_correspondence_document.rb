class CreateCorrespondenceDocument < ActiveRecord::Migration[5.2]
  def change
    create_table :correspondence_documents do |t|
      t.belongs_to :correspondence, index: true, foreign_key: true
      t.uuid :uuid, comment:"Reference to document in AWS S3"
      t.string :document_file_number, comment:"From CMP documents table"
      t.string :vbms_document_id, comment:"From CMP documents table"
    end
  end
end
