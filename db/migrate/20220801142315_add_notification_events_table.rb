class AddNotificationEventsTable < Caseflow::Migration
  def change
    create_table :notification_events, {id: false} do |t|
        t.string     :event_type, null: false, primary_key: true, comment: "Type of Event"
        t.uuid       :email_template_id, null: false, comment: "Staging Email Template UUID"
        t.uuid       :sms_template_id, null: false, comment: "Staging SMS Template UUID"
    end
  end
end