# frozen_string_literal: true

class CreateHearingEmailRecipient < Caseflow::Migration
  def change
    create_table :hearing_email_recipients,
                 comment: "Add reminder email recipients for non-virtual hearings" do |t|

      t.belongs_to :hearing,
                   polymorphic: true,
                   index: true,
                   comment: "Associated hearing"

      t.string     :email_address,
                   comment: "The recipient's email address"

      t.string     :timezone,
                   limit: 50,
                   comment: "The recipient's timezone"

      t.string     :type,
                   comment: "the subclass name (i.e. AppellantHearingEmailRecipient)"

      t.boolean    :email_sent,
                   default: false,
                   null: false,
                   comment: "Indicates whether or not a notification email was sent to the recipient."

      t.timestamps
    end
  end
end
