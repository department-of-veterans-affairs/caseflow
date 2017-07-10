class AddV2ToCertifications < ActiveRecord::Migration
  def change
    add_column :certifications, :v2, :boolean
  end
end
