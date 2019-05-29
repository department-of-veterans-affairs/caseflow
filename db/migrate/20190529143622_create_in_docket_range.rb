class CreateInDocketRange < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :docket_range_date, :date
  end
end
