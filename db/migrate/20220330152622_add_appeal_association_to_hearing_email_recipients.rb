class AddAppealAssociationToHearingEmailRecipients < Caseflow::Migration
  def change
    add_column :hearing_email_recipients, :appeal_id, :bigint, comment: "The ID of the appeal this email recipient is associated with"
    add_column :hearing_email_recipients, :appeal_type, :string, comment: "The type of appeal this email recipient is associated with"

    add_safe_index :hearing_email_recipients, [:appeal_type, :appeal_id]
  end
end
