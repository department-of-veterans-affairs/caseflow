class CreateEstablishClaims < ActiveRecord::Migration
  def change
    create_table :establish_claims do |t|
      t.integer :task_id
      t.integer :decision_type
      t.datetime :outcoding_date

      t.timestamps null: false
    end
  end
end
