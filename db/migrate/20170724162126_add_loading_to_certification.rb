class AddLoadingToCertification < ActiveRecord::Migration[5.1]
  def change
    add_column :certifications, :loading_data, :boolean
    add_column :certifications, :loading_data_failed, :boolean
  end
end
