class CreateInDocketRange < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :docket_range_date, :date, comment: "Date that appeal was added to hearing docket range."
  end
end
