class CreateInDocketRange < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :in_docket_range, :date
  end
end
