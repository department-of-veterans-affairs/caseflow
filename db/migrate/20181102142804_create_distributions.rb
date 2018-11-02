class CreateDistributions < ActiveRecord::Migration[5.1]
  def change
    create_table :distributions do |t|
      t.integer :judge_id
      t.jsonb :statistics
      t.datetime "completed_at"

      t.timestamps
    end
  end
end
