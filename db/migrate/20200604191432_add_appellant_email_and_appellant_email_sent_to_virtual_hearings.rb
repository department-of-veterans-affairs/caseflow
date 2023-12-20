class AddAppellantEmailAndAppellantEmailSentToVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :appellant_email, :string, comment: "Appellant's email address"
    add_column :virtual_hearings, :appellant_email_sent, :boolean, null: false, default: false, comment: "Determines whether or not a notification email was sent to the appellant"
  end
end
