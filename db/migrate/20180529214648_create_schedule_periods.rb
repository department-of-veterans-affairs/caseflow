class CreateSchedulePeriods < ActiveRecord::Migration[5.1]
  def change
    create_table :schedule_periods do |t|
      t.string     :type, null: false
      t.belongs_to :user
      t.datetime   :start_date
      t.datetime   :end_date

      t.timestamps null: false
    end
  end
end
