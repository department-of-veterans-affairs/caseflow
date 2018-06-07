class AddFileToSchedulePeriod < ActiveRecord::Migration[5.1]
  def change
    add_column :schedule_periods, :file_name, :string
    add_column :schedule_periods, :file_path, :string
  end
end
