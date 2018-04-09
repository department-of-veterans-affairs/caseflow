class AddV2ToCertifications < ActiveRecord::Migration[5.1]
  def change
    add_column :certifications, :v2, :boolean
  end
end
