class AddSourceToApiViews < ActiveRecord::Migration[5.1]
  def change
    add_column :api_views, :source, :string
  end
end
