class UpdateVbmsDocTypeIdInCorrespondenceDocuments < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      add_column :correspondence_documents, :vbms_document_type_id, :bigint, comment: "From CMP documents table"
      remove_column :correspondence_documents, :vbms_document_id
    end
  end

  def down
    safety_assured do
      add_column :correspondence_documents, :vbms_document_id, :string, comment: "From CMP documents table"
      remove_column :correspondence_documents, :vbms_document_type_id
    end
  end
end
