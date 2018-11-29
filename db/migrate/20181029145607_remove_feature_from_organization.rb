class RemoveFeatureFromOrganization < ActiveRecord::Migration[5.1]
  def change
    remove_column :organizations, :feature, :string
  end
end
