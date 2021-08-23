class AddUpdatedStatusColumnsToSentHearingEmailEvents < Caseflow::Migration
  def change
    add_column :sent_hearing_email_events, :sent_status, :boolean, comment: "This column keeps track of whether the email was sent or not."
    add_column :sent_hearing_email_events, :sent_status_checked_at, :datetime, comment: "The date the status was last checked/updated in the GovDelivery API."
    add_column :sent_hearing_email_events, :sent_status_email_external_message_id, :string, comment: "The GovDelivery external message id for the email sent to the coordinator."
  end
end
