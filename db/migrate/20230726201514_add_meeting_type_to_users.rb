class AddMeetingTypeToUsers < Caseflow::Migration[5.2]
  def change
    add_column :users, :meeting_type, :varChar, default: "pexip", comment: "Video Conferencing Application Type"
  end
end
