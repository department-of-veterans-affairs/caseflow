class CreateAllocation < ActiveRecord::Migration[5.1]
  def change
    create_table :allocations do |t|
      t.belongs_to :schedule_period, null: false
      t.string     :regional_office, null: false
      t.float      :allocated_days, null: false

      t.timestamps null: false
    end
  end
end
