class AddNotificationsTable < Caseflow::Migration
  def change
    create_table :notifications do |t|
      t.belongs_to :notification_events
      t.string     :appeals_id, null: false, comment: "ID of the Appeal"
      t.string     :appeals_type, null: false, comment: "Type of Appeal"
      t.string     :event_type, null: false, comment: "Type of Event"
      t.date       :event_date, null: false, comment: "Date of Event"
      t.string     :participant_id, comment: "ID of Participant"
      t.timestamp  :notified_at, null: false, comment: "Time Notification was created"
      t.string     :notification_type, null: false, comment: "Type of Notification that was created"
      t.string     :email_notification_status, comment: "Status of the Email Notification"
      t.string     :sms_notification_status, comment: "Status of SMS/Text Notification"
      t.string     :recipient_email, comment: "Participant's Email Address"
      t.string     :recipient_phone_number, comment: "Participants Phone Number"
      t.text       :notification_content, null: false, comment: "Full Text Content of Notification"
      t.timestamp  :created_at, comment: "Timestamp of when Noticiation was Created"
      t.timestamp  :updated_at, comment: "TImestamp of when Notification was Updated"
  end

  add_foreign_key "notifications", "notification_events", column: "event_type", primary_key: "event_type", validate:false
  end
end
