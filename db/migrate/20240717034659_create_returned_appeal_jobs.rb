class CreateReturnedAppealJobs < ActiveRecord::Migration[6.0]
  def change
    create_table :returned_appeal_jobs do |t|
      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamp :errored_at
      t.json :stats
      t.text :returned_appeals, array: true, default: []

      t.timestamps
    end
  end
end
