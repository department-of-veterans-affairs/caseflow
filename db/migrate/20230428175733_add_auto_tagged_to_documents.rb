class AddAutoTaggedToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :documents, :auto_tagged, :boolean
  end
end
