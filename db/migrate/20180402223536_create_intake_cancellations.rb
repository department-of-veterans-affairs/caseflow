class CreateIntakeCancellations < ActiveRecord::Migration
  def change
    create_table :intake_cancellations do |t|
      t.belongs_to :intake
      t.string :cancellation_reason
      t.string :other_reason
    end
  end
end
