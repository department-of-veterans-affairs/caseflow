class AddUserToDocumentsTag < ActiveRecord::Migration[5.1]
  def change
    add_column :documents_tags, :id, :primary_key
  end
end
