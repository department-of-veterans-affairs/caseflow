class AddSystemAdminEventsTable < Caseflow::Migration
  def change
    create_table :system_admin_events do |t|
      t.references :user, foreign_key: true, null: false, comment: "User who initiated the event"
      t.string     :event_type, null: false, comment: "Type of event"
      t.json       :info, comment: "Additional information about the event"
      t.timestamp  :created_at, comment: "Timestamp of when event was initiated"
      t.timestamp  :updated_at, comment: "Timestamp of when event was last updated"
      t.timestamp  :completed_at, comment: "Timestamp of when event was completed without error"
      t.timestamp  :errored_at, comment: "Timestamp of when event failed due to error"
    end
  end
end
