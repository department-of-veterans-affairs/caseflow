class CreateSentHearingEmailEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :sent_hearing_email_events, comment: "Events related to hearings notification emails" do |t|
      t.string "external_message_id", comment: "The ID returned by the GovDelivery API when we send an email"
      t.string "recipient_role", comment: "The role of the recipient: veteran, representative, judge"
      t.string "email_type", comment: "The type of email sent: cancellation, confirmation, update"
      t.string "email_address", comment: "Address the email was sent to"
      t.datetime "sent_at", null: false, comment: "The date and time the email was sent"

      t.references :sent_by, null: false, comment: "User who initiated sending the email"
      t.references :hearing, polymorphic: true, null: false, comment: "Associated hearing"
    end
  end
end
