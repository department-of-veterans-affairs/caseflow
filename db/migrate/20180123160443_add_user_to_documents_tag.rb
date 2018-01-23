class AddUserToDocumentsTag < ActiveRecord::Migration
  def change
    add_column :documents_tags, :user_id, :integer
  end
end
