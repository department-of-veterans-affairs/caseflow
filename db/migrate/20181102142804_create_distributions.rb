class CreateDistributions < ActiveRecord::Migration[5.1]
  def change
    create_table :distributions do |t|
      t.integer :judge_id
      t.string :status
      t.json :statistics
      t.datetime :completed_at

      t.timestamps
    end
  end
end
