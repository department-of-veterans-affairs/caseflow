class CreateSchedulePeriods < ActiveRecord::Migration[5.1]
  def change
    create_table :schedule_periods do |t|
      t.string     :type, null: false
      t.belongs_to :user, null: false
      t.date       :start_date, null: false
      t.date       :end_date, null: false
      t.boolean    :finalized

      t.timestamps null: false
    end
  end
end
