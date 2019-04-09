class MakeDesicionDocumentPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_documents, :appeal_type, :string
  end
end
