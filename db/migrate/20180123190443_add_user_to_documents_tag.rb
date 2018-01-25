class AddUserToDocumentsTag < ActiveRecord::Migration
  def change
    add_column :documents_tags, :id, :primary_key
  end
end
