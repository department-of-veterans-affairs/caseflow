class AddMeetingTypeToUsers < Caseflow::Migration
  def up
    add_column :users, :meeting_type, :varChar, default: "pexip", comment: "Video Conferencing Application Type"
  end

  def down
    remove_column :users, :meeting_type
  end
end
