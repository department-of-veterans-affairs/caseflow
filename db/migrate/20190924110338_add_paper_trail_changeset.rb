class AddPaperTrailChangeset < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :object_changes, :text
  end
end
