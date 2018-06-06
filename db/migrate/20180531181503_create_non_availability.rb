class CreateNonAvailability < ActiveRecord::Migration[5.1]
  def change
    create_table :non_availabilities do |t|
      t.belongs_to :schedule_period, null: false
      t.string     :type, null: false
      t.date       :date, null: false
      t.string     :object_identifier, null: false

      t.timestamps null: false
    end
  end
end
