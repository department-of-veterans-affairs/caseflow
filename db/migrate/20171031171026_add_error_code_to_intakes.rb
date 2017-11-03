class AddErrorCodeToIntakes < ActiveRecord::Migration
  safety_assured

  def change
    add_column :intakes, :error_code, :string
    
    change_column_null :intakes, :detail_id, true
    change_column_null :intakes, :detail_type, true
  end
end
