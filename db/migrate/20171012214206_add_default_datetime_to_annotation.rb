class AddDefaultDatetimeToAnnotation < ActiveRecord::Migration
  def change
    change_column_default :annotations, :created_at, Time.now.utc
    change_column_default :annotations, :updated_at, Time.now.utc
  end
end
