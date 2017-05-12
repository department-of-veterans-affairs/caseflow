class CreateCertificationCancellations < ActiveRecord::Migration
  def change
    create_table :certification_cancellations do |t|
      t.belongs_to :certification
      t.string :cancellation_reason
      t.string :other_reason
      t.string :email
    end
    add_index(:certification_cancellations, :certification_id, unique: true)
  end
end
