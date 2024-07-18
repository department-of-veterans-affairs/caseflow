class CreateReturnedAppealJobs < Caseflow::Migration
  def change
    create_table :returned_appeal_jobs do |t|
      t.timestamp :start
      t.timestamp :end
      t.timestamp :errored
      t.json :stats
      t.text :returned_appeals, array: true, default: []

      t.timestamps
    end
  end
end
