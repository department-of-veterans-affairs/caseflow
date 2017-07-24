class AddLoadingToCertification < ActiveRecord::Migration
  def change
    add_column :certifications, :loading, :boolean
    add_column :certifications, :error, :boolean
  end
end
