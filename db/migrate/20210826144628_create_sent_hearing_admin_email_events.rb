class CreateSentHearingAdminEmailEvents < Caseflow::Migration
  def change
    create_table :sent_hearing_admin_email_events do |t|
      t.references :sent_hearing_email_event, foreign_key: true, index: { name: "index_admin_email_events_on_hearing_email_event_id" }, comment: "Associated sent hearing email event."
      t.string     :external_message_id, comment: "The ID returned by the GovDelivery API when we send an email."

      t.timestamps
    end
  end
end
