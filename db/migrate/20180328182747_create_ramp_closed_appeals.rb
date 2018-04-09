class CreateRampClosedAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :ramp_closed_appeals do |t|
      t.string      :vacols_id, null: false
      t.belongs_to  :ramp_election, foreign_key: true
      t.date        :nod_date
    end
  end
end
