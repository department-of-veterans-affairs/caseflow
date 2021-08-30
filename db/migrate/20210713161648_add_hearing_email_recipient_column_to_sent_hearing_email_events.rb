class AddHearingEmailRecipientColumnToSentHearingEmailEvents < Caseflow::Migration
  def change
    safety_assured do
      add_reference :sent_hearing_email_events,
                    :email_recipient,
                    index: false,
                    foreign_key: { to_table: :hearing_email_recipients },
                    comment: "Associated HearingEmailRecipient"
    end
  end
end
