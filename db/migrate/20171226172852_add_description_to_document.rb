class AddDescriptionToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :description, :string
  end
end
