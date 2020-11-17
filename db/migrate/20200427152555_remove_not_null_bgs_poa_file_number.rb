class RemoveNotNullBgsPoaFileNumber < ActiveRecord::Migration[5.2]
  def change
    change_column_null :bgs_power_of_attorneys, :file_number, true
  end
end
