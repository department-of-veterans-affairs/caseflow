class CreateSchedulePeriods < ActiveRecord::Migration[5.1]
  def change
    create_table :schedule_periods do |t|
      t.string     :type, null: false
      t.belongs_to :user
      t.date       :start_date
      t.date       :end_date

      t.timestamps null: false
    end
  end
end
