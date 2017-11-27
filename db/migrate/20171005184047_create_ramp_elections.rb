class CreateRampElections < ActiveRecord::Migration
  safety_assured # this is a new and unused table

  def change
    create_table :ramp_elections do |t|
      t.string     :veteran_file_number, null: false
      t.date       :notice_date, null: false
      t.date       :receipt_date
      t.string     :option_selected
    end

    add_index(:ramp_elections, :veteran_file_number)
  end
end
