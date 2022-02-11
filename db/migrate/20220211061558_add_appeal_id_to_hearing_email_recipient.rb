class AddAppealIdToHearingEmailRecipient < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key "hearing_email_recipients", "appeals", column: "appeal_id", validate: false
    validate_foreign_key "hearing_email_recipients", column: "appeal_id"
  end
end
