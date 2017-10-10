class CreateRampElections < ActiveRecord::Migration
  def change
    create_table :ramp_elections do |t|
      t.string     :veteran_file_number, null: :false
      t.date       :notice_date, null: :false
      t.date       :receipt_date
      t.string     :option_selected
    end
  end
end
