class AddMpiUpdatePersonEventsTable < Caseflow::Migration
  def change
    create_table :mpi_update_person_events do |t|
      t.references :api_key, foreign_key: true, null: false, comment: "API Key used to initiate the event"
      t.string     :update_type, null: false, comment: "Type or Result of update"
      t.json       :info, comment: "Additional information about the update"
      t.timestamp  :created_at, comment: "Timestamp of when update was initiated"
      t.timestamp  :completed_at, comment: "Timestamp of when update was completed, regardless of success or failure"
    end
  end
end
