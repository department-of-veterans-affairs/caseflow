class AddFileToSchedulePeriod < ActiveRecord::Migration[5.1]
  def change
    add_column :schedule_periods, :file_name, :string, null: false
  end
end
