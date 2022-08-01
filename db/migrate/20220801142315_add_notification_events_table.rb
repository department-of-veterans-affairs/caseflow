class AddNotificationEventsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :notification_events, :primary_key => :event_type do |t|
        t.has_many    :notifications
        t.strings     :event_type, null: false, comment: "Type of Event"
        t.uuid        :template_id, null: false, comment: "UUID of the VANotify Template"
    end
  end
end



=begin
def change
  create_table :notifications do |t|
      t.belongs_to :notifcation_events
      t.serial     :id, null: false, comment: "Autoincremented notification ID"
      t.string     :appeals_id, null: false, comment: "ID of the Appeal"
      t.string     :appeals_type, null: false, comment: "Type of Appeal"
      t.string     :event_type, null: false, foreign_key: true, comment: "Type of Event"
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

  add_foreign_key "event_type", "notification_events", column: "event_type", validate:false
end
end
=end

