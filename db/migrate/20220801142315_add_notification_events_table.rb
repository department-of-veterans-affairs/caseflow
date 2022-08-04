class AddNotificationEventsTable < Caseflow::Migration
  def change
    create_table :notification_events, {id: false} do |t|
        t.string     :event_type, primary_key: true, null: false, comment: "Type of Event"
        t.uuid        :template_id, null: false, comment: "UUID of the VANotify Template"
    end
  end
end