class AddDatetimeToAnnotation < ActiveRecord::Migration[5.1]
  def change
    add_column :annotations, :created_at, :datetime
    add_column :annotations, :updated_at, :datetime
  end
end
