class AddAppealTypeToHearingEmailRecipients < ActiveRecord::Migration[5.2]
  def change
    add_column :hearing_email_recipients, :appeal_type, :string, null:false, comment: "Whether appeal_id is for AMA or legacy appeals"
  end
end
