class AddReminderEmailFlagsToVirtualHearings < Caseflow::Migration
  def change
    add_column :virtual_hearings,
               :appellant_reminder_sent_at,
               :datetime,
               comment: "The datetime the last reminder email was sent to the appellant."
    add_column :virtual_hearings,
               :representative_reminder_sent_at,
               :datetime,
               comment: "The datetime the last reminder email was sent to the representative."
  end
end
