class AddDescriptionToVbmsDocumentTypes < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      add_column :vbms_document_types, :description , :string, comment: "Document type"
    end
  end

  def down
    safety_assured do
      remove_column :vbms_document_types, :description , :string, comment: "Document type"
    end
  end
end
