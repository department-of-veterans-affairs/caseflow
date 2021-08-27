class AddUpdatedStatusColumnsToSentHearingEmailEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :sent_hearing_email_events, :send_successful, :boolean, comment: "This column keeps track of whether the email was sent or not"
    add_column :sent_hearing_email_events, :send_successful_checked_at, :datetime, comment: "The date the status was last checked/updated in the GovDelivery API"
  end
end
