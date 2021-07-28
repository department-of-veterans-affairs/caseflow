# frozen_string_literal: true

class CreateHearingEmailRecipient < Caseflow::Migration
  def change
    create_table :hearing_email_recipients,
                 comment: "Recipients of hearings-related emails" do |t|

      t.belongs_to :hearing,
                   polymorphic: true,
                   index: true,
                   comment: "Associated hearing"

      t.string     :email_address,
                   comment: "PII. The recipient's email address"

      t.string     :timezone,
                   limit: 50,
                   comment: "The recipient's timezone"

      t.string     :type,
                   comment: "The subclass name (i.e. AppellantHearingEmailRecipient)"

      t.boolean    :email_sent,
                   default: false,
                   null: false,
                   comment: "Indicates if a notification email was sent to the recipient."

      t.timestamps
    end
  end
end
