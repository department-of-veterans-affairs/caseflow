class AddAmaOnlyToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :ama_only, :boolean, :default => false
  end
end
