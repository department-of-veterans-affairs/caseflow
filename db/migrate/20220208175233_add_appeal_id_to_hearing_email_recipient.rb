class AddAppealIdToHearingEmailRecipient < ActiveRecord::Migration[5.2]
  def change
    add_column :hearing_email_recipients, :appeal_id, :integer, foreign_key: true
  end
end
