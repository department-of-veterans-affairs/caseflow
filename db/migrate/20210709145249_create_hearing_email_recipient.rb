# frozen_string_literal: true

class CreateHearingEmailRecipient < Caseflow::Migration
  def change
    create_table :hearing_email_recipients,
                 comment: "Add reminder email recipients for non-virtual hearings" do |t|
      t.string "email_address", comment: "The recipient's email address"
      t.bigint "hearing_id", comment: "Associated hearing id"
      t.string "hearing_type", comment: "'Hearing' or 'LegacyHearing'"
      t.string "timezone", limit: 50, comment: "The recipient's timezone"
      t.string "type", comment: "the subclass name (i.e. AppellantHearingEmailRecipient)"
      # ... plus created_at, updated_at, indexes, etc.
    end
  end
end
