class AddIndicesToSentHearingEmailEvents < Caseflow::Migration
  def change
    safety_assured do
      add_safe_index :sent_hearing_email_events, [:email_address]
      add_safe_index :sent_hearing_email_events, [:recipient_role]
      add_safe_index :sent_hearing_email_events, [:email_type]
    end
  end
end
