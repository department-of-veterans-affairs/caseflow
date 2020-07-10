class RemoveVeteranEmailAndVeteranEmailSentFromVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :virtual_hearings, :veteran_email
      remove_column :virtual_hearings, :veteran_email_sent
    end
  end
end
