class CreateSchedulableCutoffDates < ActiveRecord::Migration[6.1]
  def change
    create_table :schedulable_cutoff_dates do |t|
      t.date :cutoff_date
      t.bigint :created_by_id, null: false, references: [:users, :id]

      t.timestamps null: false
    end
  end

  def down
    drop_table :schedulable_cutoff_dates
  end
end
