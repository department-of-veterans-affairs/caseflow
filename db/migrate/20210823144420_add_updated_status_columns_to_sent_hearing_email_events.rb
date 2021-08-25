class AddUpdatedStatusColumnsToSentHearingEmailEvents < Caseflow::Migration
  def change
    add_column :sent_hearing_email_events, :email_sent, :boolean, comment: "This column keeps track of whether the email was sent or not"
    add_column :sent_hearing_email_events, :sent_status_checked_at, :datetime, comment: "The date the status was last checked/updated in the GovDelivery API"
    add_column :sent_hearing_email_events, :sent_status_email_external_message_id, :string, comment: "The GovDelivery message ID for the failure email sent in case the first email fails to send. This is different from the external_message_id that tracks the first email sent"
    add_column :sent_hearing_email_events, :sent_status_email_attempted_at, :datetime, comment: "The date the failure email was attempted to be sent"
  end
end
